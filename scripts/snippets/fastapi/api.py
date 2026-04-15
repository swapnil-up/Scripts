@app.get("/__var__")
async def __var__():
    return {"message": "__var__"}
