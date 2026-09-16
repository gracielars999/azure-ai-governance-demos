import sys
sys.stdout.reconfigure(encoding="utf-8")
from azure.ai.projects import AIProjectClient
from azure.identity import AzureCliCredential

ENDPOINT = "https://aif-banca-ol0k4.services.ai.azure.com/api/projects/proj-banca-disputas"
AGENT = "Aria-Disputas-Reembolsos"

proj = AIProjectClient(endpoint=ENDPOINT, credential=AzureCliCredential(), allow_preview=True)
client = proj.get_openai_client(agent_name=AGENT)

def ask(q):
    print("\n" + "=" * 70)
    print("Q:", q)
    r = client.responses.create(model="gpt-4o", input=q)
    tools = []
    for item in getattr(r, "output", []) or []:
        t = getattr(item, "type", None)
        if t and t != "message":
            tools.append(t)
    print("TOOLS USED:", tools or "(none)")
    print("ANSWER:", (getattr(r, "output_text", "") or "")[:1200])

ask("Cuantos dias tengo para disputar un cargo por fraude?")
ask("Que es un contracargo segun las reglas generales de las redes Visa y Mastercard?")
