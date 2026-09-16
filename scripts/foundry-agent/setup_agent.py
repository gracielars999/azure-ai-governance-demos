"""
Crea el agente de Foundry "Aria" (Disputas y Reembolsos, Banco Contoso)
con conocimiento (file_search) sobre las políticas en español.

Auth: DefaultAzureCredential (usa 'az login').
Requisitos: azure-ai-projects, azure-ai-agents, azure-identity
"""
import os
import sys
import glob
import json

from azure.identity import AzureCliCredential
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import FileSearchTool, FilePurpose

ENDPOINT = os.environ["PROJECT_ENDPOINT"]
MODEL = os.environ.get("MODEL_DEPLOYMENT", "gpt-4o")
KNOWLEDGE_DIR = os.environ["KNOWLEDGE_DIR"]
INSTRUCTIONS_FILE = os.environ["INSTRUCTIONS_FILE"]
AGENT_NAME = os.environ.get("AGENT_NAME", "Aria-Disputas-Reembolsos")

with open(INSTRUCTIONS_FILE, "r", encoding="utf-8") as f:
    instructions = f.read()

# Documentos de conocimiento (grounding)
doc_paths = sorted(
    p for p in glob.glob(os.path.join(KNOWLEDGE_DIR, "*.md"))
    if not p.endswith("agente-instrucciones.md")
)
print(f"Documentos a subir: {[os.path.basename(p) for p in doc_paths]}")

cred = AzureCliCredential(process_timeout=90)
agents = AgentsClient(endpoint=ENDPOINT, credential=cred)

# 1) Subir archivos
file_ids = []
for path in doc_paths:
    uploaded = agents.files.upload_and_poll(file_path=path, purpose=FilePurpose.AGENTS)
    print(f"  subido {os.path.basename(path)} -> {uploaded.id}")
    file_ids.append(uploaded.id)

# 2) Vector store (Foundry IQ / conocimiento)
vs = agents.vector_stores.create_and_poll(file_ids=file_ids, name="banca-kb-disputas")
print(f"Vector store: {vs.id} (status={vs.status})")

# 3) Herramienta file_search
fs = FileSearchTool(vector_store_ids=[vs.id])

# 4) Crear el agente
agent = agents.create_agent(
    model=MODEL,
    name=AGENT_NAME,
    description="Agente de disputas y reembolsos de Banco Contoso (demo banca).",
    instructions=instructions,
    tools=fs.definitions,
    tool_resources=fs.resources,
    temperature=0.2,
)
print(f"AGENTE CREADO: {agent.id}  nombre={agent.name}")

out = {
    "agent_id": agent.id,
    "agent_name": agent.name,
    "vector_store_id": vs.id,
    "file_ids": file_ids,
    "model": MODEL,
}
with open(os.environ.get("OUTPUT_FILE", "agent_info.json"), "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
print("OK ->", json.dumps(out, ensure_ascii=False))
