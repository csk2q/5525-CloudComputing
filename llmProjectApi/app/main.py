import codecs
import os
from typing import Union

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from llama_cpp import Llama
from pydantic import BaseModel
from brewHelper import BrewHelper, RubyParser

# Initialize FastAPI app
app = FastAPI(title="Mini LLM API")

@app.get("/")
def read_root():
    file_path = os.path.abspath("static/index.html")
    return FileResponse(file_path, media_type="text/html")

# Define request models
class PromptRequest(BaseModel):
    prompt: str
    max_tokens: int = 128
    
    
# Load the model (assumes a small gguf model is downloaded locally)
MODEL_PATH = "models/Qwen3-0.6B-Q4_K_M.gguf"  # Replace with your actual path
if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError(f"Model not found at path: {MODEL_PATH}")

llm = Llama(
    model_path=MODEL_PATH,     
    # n_ctx=512,      # lower context
    n_ctx=3072,
    n_batch=32,     # smaller batches
    n_threads=2,    # match vCPUs
    use_mlock=False, # avoid locking memory
    verbose=False)

def singleChatCompletion(prompt: str, maxTokens = 128):
    try:
        response = llm.create_chat_completion(
            messages=[
                {"role": "user", "content": prompt},
                {"role": "system", "content": "/no_think"}
            ],
            ## For non-thinking mode, we suggest using Temperature=0.7, TopP=0.8, TopK=20, and MinP=0.
            temperature=0.7,
            top_p=0.8,
            top_k=20,
            min_p=0,
            max_tokens=maxTokens,
        )
        return response["choices"][0]["message"]["content"].split("</think>")[1].lstrip() # type: ignore
    except Exception as e:
        return f"Unable to serve your request.\nError: {e}"

def singleChatReply(prompt: str, maxTokens = 4096):
    try:
        response = llm.create_chat_completion(
            messages=[
                {"role": "user", "content": f"Q: {prompt} \nA:"},
                {"role": "system", "content": "Answer in English, unless asked otherwise by the user. /no_think"}
            ],
            ## For non-thinking mode, we suggest using Temperature=0.7, TopP=0.8, TopK=20, and MinP=0.
            temperature=0.7,
            top_p=0.8,
            top_k=20,
            min_p=0,
            max_tokens=maxTokens,
        )
        # return response["choices"][0]["message"]["content"].split("</think>")[1].lstrip() # type: ignore
        return response["choices"][0]["message"]["content"] # type: ignore
    except Exception as e:
        return f"Unable to serve your request.\nError: {e}"
    

@app.post("/predict")
def predict(req: PromptRequest):
    """
        Have the LLM finish (predict) the rest of your input.
    """
    try:
        return singleChatCompletion(req.prompt, req.max_tokens)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ask")
def ask_llm(req: PromptRequest):
    """
        Ask the LLM a question.
    """
    try:
        return singleChatReply(req.prompt, req.max_tokens)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    

# Set up the git repos
brew = BrewHelper()
brew.updateCoreRepo(brew.rootDir)

@app.get("/newFormula")
def get_newFormula():
    date = "1 week"
    newFormulaInfo = []
    for newFormulaPath in brew.getNewFormula(date):
        fullPath = brew.formulaDir + '/' + newFormulaPath
        print(fullPath)
        newFormulaInfo.append(str(RubyParser(fullPath)))
    
    prompt = f"Summarize the following list of newly added applications called Formula that have been added this past {date} into a brief overview. Include a summary paragraph written like a radio commentator.\n" + '\n'.join(newFormulaInfo)
    tokens = llm.tokenize(prompt.encode("utf-8"))
    print(f'Token count: {len(tokens)}')
    # try:
    response = singleChatCompletion(prompt, 1024)
    # print(response)
    output = prompt + f'\n----\n' + response
    returnValue = codecs.decode(output, 'unicode_escape')
    # print(returnValue)
    return returnValue
    
    # except Exception as e:
        # raise HTTPException(status_code=500, detail=str(e))



