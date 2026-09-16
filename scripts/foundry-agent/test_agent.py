"""Prueba rápida del agente de Foundry: crea un hilo, envía una pregunta y muestra la respuesta."""
import os
from azure.identity import AzureCliCredential
from azure.ai.agents import AgentsClient

ENDPOINT = os.environ["PROJECT_ENDPOINT"]
AGENT_ID = os.environ["AGENT_ID"]
QUESTION = os.environ.get("QUESTION", "No reconozco un cargo de $1,800 en mi tarjeta terminación 4321. ¿Qué puedo hacer y en qué plazo?")

cred = AzureCliCredential(process_timeout=90)
agents = AgentsClient(endpoint=ENDPOINT, credential=cred)

thread = agents.threads.create()
agents.messages.create(thread_id=thread.id, role="user", content=QUESTION)
run = agents.runs.create_and_process(thread_id=thread.id, agent_id=AGENT_ID)
print("RUN STATUS:", run.status)
if run.status == "failed":
    print("ERROR:", run.last_error)

msgs = agents.messages.list(thread_id=thread.id)
for m in msgs:
    if m.role == "assistant":
        for c in m.content:
            if getattr(c, "type", None) == "text":
                print("\n=== RESPUESTA DEL AGENTE ===\n")
                print(c.text.value)
        break
