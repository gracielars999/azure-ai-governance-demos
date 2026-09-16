"""
Banco Contoso · Aria — Agente de Disputas y Reembolsos
Backend FastAPI que enruta el chat a través del AI Gateway (Azure API Management).

Demuestra en vivo los pilares de la demo:
- Gobernanza  -> selección de subscription key por Unidad de Negocio (Retail / Empresas)
- Seguridad   -> el gateway aplica Content Safety / detección de jailbreak (managed identity al backend)
- AI Gateway  -> todo el tráfico pasa por APIM (rate/token limit, caché semántica)
- AI FinOps   -> lee cabeceras de tokens del gateway y estima costo por consumidor
- Foundry     -> el mismo modelo/persona del agente de Foundry (grounding con políticas)
"""
import os
import time
import glob
import pathlib

import requests
from fastapi import FastAPI
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# Configuración (App Settings / variables de entorno)
# ---------------------------------------------------------------------------
APIM_GATEWAY_URL = os.environ.get("APIM_GATEWAY_URL", "").rstrip("/")
APIM_API_PATH = os.environ.get("APIM_API_PATH", "banca").strip("/")
MODEL_DEPLOYMENT = os.environ.get("MODEL_DEPLOYMENT", "gpt-4o")
API_VERSION = os.environ.get("API_VERSION", "2024-10-21")

# Llaves de subscripción de APIM por Unidad de Negocio (gobernanza / chargeback)
SUBKEYS = {
    "retail": os.environ.get("SUBKEY_RETAIL", ""),
    "empresas": os.environ.get("SUBKEY_EMPRESAS", ""),
}

# Precio de referencia gpt-4o (USD por 1K tokens) — editable para el demo de FinOps
PRICE_INPUT_PER_1K = float(os.environ.get("PRICE_INPUT_PER_1K", "0.0025"))
PRICE_OUTPUT_PER_1K = float(os.environ.get("PRICE_OUTPUT_PER_1K", "0.010"))
USD_TO_MXN = float(os.environ.get("USD_TO_MXN", "18.5"))

BU_LABELS = {"retail": "Banca Retail", "empresas": "Banca Empresas"}

BASE_DIR = pathlib.Path(__file__).resolve().parent
FRONTEND_DIR = BASE_DIR / "frontend"
KNOWLEDGE_DIR = BASE_DIR / "knowledge"


def build_system_prompt() -> str:
    """Grounding: instrucciones del agente + base de conocimiento (políticas)."""
    parts = []
    instr = KNOWLEDGE_DIR / "agente-instrucciones.md"
    if instr.exists():
        parts.append(instr.read_text(encoding="utf-8"))
    kb = []
    for path in sorted(glob.glob(str(KNOWLEDGE_DIR / "*.md"))):
        if path.endswith("agente-instrucciones.md"):
            continue
        kb.append(pathlib.Path(path).read_text(encoding="utf-8"))
    if kb:
        parts.append("\n\n# BASE DE CONOCIMIENTO (fuente de verdad)\n\n" + "\n\n---\n\n".join(kb))
    if not parts:
        return "Eres Aria, agente de disputas y reembolsos de Banco Contoso. Responde en español."
    return "\n\n".join(parts)


SYSTEM_PROMPT = build_system_prompt()

app = FastAPI(title="Banco Contoso · Aria")


class ChatRequest(BaseModel):
    message: str
    business_unit: str = "retail"
    history: list | None = None


@app.get("/api/config")
def get_config():
    return {
        "business_units": [{"id": k, "label": v} for k, v in BU_LABELS.items()],
        "model": MODEL_DEPLOYMENT,
        "gateway_configured": bool(APIM_GATEWAY_URL),
        "keys_configured": {k: bool(v) for k, v in SUBKEYS.items()},
    }


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.post("/api/chat")
def chat(req: ChatRequest):
    bu = (req.business_unit or "retail").lower()
    if bu not in SUBKEYS:
        bu = "retail"
    sub_key = SUBKEYS.get(bu, "")

    if not APIM_GATEWAY_URL:
        return JSONResponse(status_code=503, content={"error": "AI Gateway (APIM) no configurado. Falta APIM_GATEWAY_URL."})
    if not sub_key:
        return JSONResponse(status_code=503, content={"error": f"Falta la subscription key para la unidad '{bu}'."})

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    for turn in (req.history or [])[-8:]:
        role = turn.get("role")
        content = turn.get("content")
        if role in ("user", "assistant") and content:
            messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": req.message})

    url = f"{APIM_GATEWAY_URL}/{APIM_API_PATH}/deployments/{MODEL_DEPLOYMENT}/chat/completions?api-version={API_VERSION}"
    headers = {
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": sub_key,
    }
    payload = {"messages": messages, "max_tokens": 800, "temperature": 0.2}

    t0 = time.time()
    try:
        r = requests.post(url, headers=headers, json=payload, timeout=90)
    except Exception as ex:  # noqa: BLE001
        return JSONResponse(status_code=502, content={"error": f"Error al llamar al gateway: {ex}"})
    latency_ms = int((time.time() - t0) * 1000)

    # Telemetría del gateway (gobernanza / FinOps / seguridad)
    gw = r.headers
    cache_status = gw.get("x-cache") or gw.get("apim-cache-status") or ("HIT" if gw.get("x-ms-semantic-cache") else "")
    telemetry = {
        "business_unit": bu,
        "business_unit_label": BU_LABELS.get(bu, bu),
        "http_status": r.status_code,
        "latency_ms": latency_ms,
        "tokens_consumed_header": gw.get("x-tokens-consumed"),
        "tokens_remaining_header": gw.get("x-tokens-remaining"),
        "cache": cache_status or "MISS",
    }

    # Content Safety / token limit bloquean con 4xx
    if r.status_code == 403 or r.status_code == 400:
        detail = ""
        try:
            detail = r.json().get("error", "")
        except Exception:  # noqa: BLE001
            detail = r.text[:300]
        return JSONResponse(status_code=200, content={
            "blocked": True,
            "reason": "content_safety" if r.status_code in (400, 403) else "policy",
            "message": "🛡️ El AI Gateway bloqueó la solicitud por política de seguridad (Content Safety / jailbreak).",
            "detail": str(detail),
            "telemetry": telemetry,
        })
    if r.status_code == 429:
        return JSONResponse(status_code=200, content={
            "blocked": True,
            "reason": "token_limit",
            "message": "⏳ Límite de tokens por minuto alcanzado (governance de costos del AI Gateway). Intenta de nuevo en un momento.",
            "telemetry": telemetry,
        })
    if r.status_code >= 400:
        return JSONResponse(status_code=200, content={
            "blocked": True,
            "reason": "error",
            "message": f"El gateway respondió {r.status_code}.",
            "detail": r.text[:400],
            "telemetry": telemetry,
        })

    data = r.json()
    answer = ""
    usage = data.get("usage", {})
    try:
        answer = data["choices"][0]["message"]["content"]
    except Exception:  # noqa: BLE001
        answer = "(sin contenido)"

    prompt_tok = usage.get("prompt_tokens", 0)
    completion_tok = usage.get("completion_tokens", 0)
    total_tok = usage.get("total_tokens", prompt_tok + completion_tok)
    full_cost_usd = (prompt_tok / 1000.0) * PRICE_INPUT_PER_1K + (completion_tok / 1000.0) * PRICE_OUTPUT_PER_1K
    is_hit = (cache_status or "").upper() == "HIT"
    # En un HIT la respuesta se sirve desde el caché del AI Gateway: 0 tokens al modelo, 0 costo.
    # Los tokens que trae el body son los que se AHORRARON al no volver a llamar al modelo.
    billed_cost_usd = 0.0 if is_hit else full_cost_usd
    saved_cost_usd = full_cost_usd if is_hit else 0.0
    telemetry.update({
        "prompt_tokens": prompt_tok,
        "completion_tokens": completion_tok,
        "total_tokens": total_tok,
        "cache_hit": is_hit,
        "billed_tokens": 0 if is_hit else total_tok,
        "cost_usd": round(billed_cost_usd, 6),
        "cost_mxn": round(billed_cost_usd * USD_TO_MXN, 4),
        "cost_saved_usd": round(saved_cost_usd, 6),
        "cost_saved_mxn": round(saved_cost_usd * USD_TO_MXN, 4),
        "tokens_saved": total_tok if is_hit else 0,
    })

    return {"blocked": False, "answer": answer, "telemetry": telemetry}


# Static frontend (SPA)
if FRONTEND_DIR.exists():
    @app.get("/")
    def index():
        return FileResponse(str(FRONTEND_DIR / "index.html"))

    app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="static")
