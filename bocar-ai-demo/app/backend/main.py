"""Bocar · BIA — asistente gobernado para una planta de manufactura automotriz."""

import glob
import os
import pathlib
import time

import requests
from fastapi import FastAPI
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

APIM_GATEWAY_URL = os.environ.get("APIM_GATEWAY_URL", "").rstrip("/")
APIM_API_PATH = os.environ.get("APIM_API_PATH", "bocar").strip("/")
MODEL_DEPLOYMENT = os.environ.get("MODEL_DEPLOYMENT", "gpt-4o")
API_VERSION = os.environ.get("API_VERSION", "2024-10-21")
SEND_HISTORY = os.environ.get("SEND_HISTORY", "0").lower() in ("1", "true", "yes")

SUBKEYS = {
    "produccion": os.environ.get("SUBKEY_PRODUCCION", ""),
    "mantenimiento": os.environ.get("SUBKEY_MANTENIMIENTO", ""),
    "cotizaciones": os.environ.get("SUBKEY_COTIZACIONES", ""),
}

PRICE_INPUT_PER_1K = float(os.environ.get("PRICE_INPUT_PER_1K", "0.0025"))
PRICE_OUTPUT_PER_1K = float(os.environ.get("PRICE_OUTPUT_PER_1K", "0.010"))
USD_TO_MXN = float(os.environ.get("USD_TO_MXN", "18.5"))

BU_LABELS = {
    "produccion": "Producción y Calidad",
    "mantenimiento": "Mantenimiento Predictivo",
    "cotizaciones": "Ingeniería y Cotizaciones",
}

BU_CONTEXT = {
    "produccion": (
        "CONTEXTO DE SESIÓN: el usuario pertenece a Producción y Calidad. "
        "Puede consultar scrap, retrabajo, costo de no calidad, causa raíz probable, OEE, "
        "producción vs. plan, tiempos muertos y lotes retenidos. Usa el Panel de Producción "
        "y Calidad. No reveles probabilidades de falla por activo, notas de órdenes de "
        "mantenimiento, históricos comerciales ni borradores de cotización."
    ),
    "mantenimiento": (
        "CONTEXTO DE SESIÓN: el usuario pertenece a Mantenimiento Predictivo. "
        "Puede consultar señales MES/historiador simuladas, riesgos por activo, órdenes de "
        "trabajo ERP simuladas y procedimientos seguros. Puede preparar una propuesta de orden, "
        "pero jamás afirmar que fue creada o ejecutarla sin aprobación humana. No reveles "
        "precios, márgenes ni históricos de cotización."
    ),
    "cotizaciones": (
        "CONTEXTO DE SESIÓN: el usuario pertenece a Ingeniería y Cotizaciones. "
        "Puede consultar el RFQ ficticio, históricos anonimizados y documentos PLM/"
        "repositorio documental simulados para generar un borrador comercial con citas. Debe marcarlo como "
        "borrador y exigir validación humana. No reveles señales de activos, órdenes de "
        "mantenimiento ni lotes retenidos."
    ),
}

BASE_DIR = pathlib.Path(__file__).resolve().parent
FRONTEND_DIR = BASE_DIR / "frontend"
KNOWLEDGE_DIR = BASE_DIR / "knowledge"
if not FRONTEND_DIR.exists():
    FRONTEND_DIR = BASE_DIR.parent / "frontend"
if not KNOWLEDGE_DIR.exists():
    KNOWLEDGE_DIR = BASE_DIR.parent.parent / "knowledge"


def build_system_prompt() -> str:
    parts: list[str] = []
    instructions = KNOWLEDGE_DIR / "agente-instrucciones.md"
    if instructions.exists():
        parts.append(instructions.read_text(encoding="utf-8"))

    knowledge: list[str] = []
    for path in sorted(glob.glob(str(KNOWLEDGE_DIR / "*.md"))):
        if path.endswith("agente-instrucciones.md"):
            continue
        knowledge.append(pathlib.Path(path).read_text(encoding="utf-8"))
    if knowledge:
        parts.append("\n\n# BASE DE CONOCIMIENTO (fuente de verdad)\n\n" + "\n\n---\n\n".join(knowledge))
    if not parts:
        return (
            "Eres BIA, asistente interno de una planta de manufactura Bocar. "
            "Responde en español y no inventes datos."
        )
    return "\n\n".join(parts)


SYSTEM_PROMPT = build_system_prompt()
app = FastAPI(title="Bocar · BIA")


class ChatRequest(BaseModel):
    message: str
    business_unit: str = "produccion"
    history: list | None = None


@app.get("/api/config")
def get_config():
    return {
        "business_units": [{"id": key, "label": value} for key, value in BU_LABELS.items()],
        "model": MODEL_DEPLOYMENT,
        "gateway_configured": bool(APIM_GATEWAY_URL),
        "keys_configured": {key: bool(value) for key, value in SUBKEYS.items()},
    }


@app.get("/healthz")
def healthz():
    return {"status": "ok"}


@app.post("/api/chat")
def chat(req: ChatRequest):
    business_unit = (req.business_unit or "produccion").lower()
    if business_unit not in SUBKEYS:
        business_unit = "produccion"
    subscription_key = SUBKEYS.get(business_unit, "")

    if not APIM_GATEWAY_URL:
        return JSONResponse(
            status_code=503,
            content={"error": "AI Gateway (APIM) no configurado. Falta APIM_GATEWAY_URL."},
        )
    if not subscription_key:
        return JSONResponse(
            status_code=503,
            content={"error": f"Falta la subscription key para la unidad '{business_unit}'."},
        )

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    business_context = BU_CONTEXT.get(business_unit)
    if business_context:
        messages.append({"role": "system", "content": business_context})
    if SEND_HISTORY:
        for turn in (req.history or [])[-8:]:
            role = turn.get("role")
            content = turn.get("content")
            if role in ("user", "assistant") and content:
                messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": req.message})

    url = (
        f"{APIM_GATEWAY_URL}/{APIM_API_PATH}/deployments/{MODEL_DEPLOYMENT}"
        f"/chat/completions?api-version={API_VERSION}"
    )
    headers = {
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": subscription_key,
    }
    payload = {"messages": messages, "max_tokens": 900, "temperature": 0.2}

    started = time.time()
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=90)
    except requests.RequestException as error:
        return JSONResponse(
            status_code=502,
            content={"error": f"Error al llamar al gateway: {error}"},
        )
    latency_ms = int((time.time() - started) * 1000)

    gateway_headers = response.headers
    cache_status = (
        gateway_headers.get("x-cache")
        or gateway_headers.get("apim-cache-status")
        or ("HIT" if gateway_headers.get("x-ms-semantic-cache") else "")
    )
    telemetry = {
        "business_unit": business_unit,
        "business_unit_label": BU_LABELS.get(business_unit, business_unit),
        "http_status": response.status_code,
        "latency_ms": latency_ms,
        "tokens_consumed_header": gateway_headers.get("x-tokens-consumed"),
        "tokens_remaining_header": gateway_headers.get("x-tokens-remaining"),
        "cache": cache_status or "MISS",
    }

    if response.status_code in (400, 403):
        try:
            detail = response.json().get("error", "")
        except ValueError:
            detail = response.text[:300]
        return {
            "blocked": True,
            "reason": "content_safety",
            "message": (
                "El AI Gateway bloqueó la solicitud por la política de seguridad "
                "(Content Safety / detección de jailbreak)."
            ),
            "detail": str(detail),
            "telemetry": telemetry,
        }
    if response.status_code == 429:
        return {
            "blocked": True,
            "reason": "token_limit",
            "message": (
                "Se alcanzó el límite de tokens por minuto de esta unidad. "
                "Espera un momento antes de intentar nuevamente."
            ),
            "telemetry": telemetry,
        }
    if response.status_code >= 400:
        return {
            "blocked": True,
            "reason": "gateway_error",
            "message": f"El gateway respondió {response.status_code}.",
            "detail": response.text[:400],
            "telemetry": telemetry,
        }

    data = response.json()
    usage = data.get("usage", {})
    try:
        answer = data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError):
        answer = "(sin contenido)"

    prompt_tokens = usage.get("prompt_tokens", 0)
    completion_tokens = usage.get("completion_tokens", 0)
    total_tokens = usage.get("total_tokens", prompt_tokens + completion_tokens)
    full_cost_usd = (
        (prompt_tokens / 1000.0) * PRICE_INPUT_PER_1K
        + (completion_tokens / 1000.0) * PRICE_OUTPUT_PER_1K
    )
    is_cache_hit = (cache_status or "").upper() == "HIT"
    billed_cost_usd = 0.0 if is_cache_hit else full_cost_usd
    saved_cost_usd = full_cost_usd if is_cache_hit else 0.0
    telemetry.update(
        {
            "prompt_tokens": prompt_tokens,
            "completion_tokens": completion_tokens,
            "total_tokens": total_tokens,
            "cache_hit": is_cache_hit,
            "billed_tokens": 0 if is_cache_hit else total_tokens,
            "cost_usd": round(billed_cost_usd, 6),
            "cost_mxn": round(billed_cost_usd * USD_TO_MXN, 4),
            "cost_saved_usd": round(saved_cost_usd, 6),
            "cost_saved_mxn": round(saved_cost_usd * USD_TO_MXN, 4),
            "tokens_saved": total_tokens if is_cache_hit else 0,
        }
    )

    return {"blocked": False, "answer": answer, "telemetry": telemetry}


if FRONTEND_DIR.exists():

    @app.get("/")
    def index():
        return FileResponse(str(FRONTEND_DIR / "index.html"))

    app.mount("/", StaticFiles(directory=str(FRONTEND_DIR), html=True), name="static")

