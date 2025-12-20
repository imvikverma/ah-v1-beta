from piper import PiperVoice
voice = PiperVoice.load(r"C:\Users\Dell\Grok\Jeeves\voices\en_US-lessac-medium\en_US-lessac-medium.onnx")
audio_chunks = voice.synthesize("test")
chunk = next(audio_chunks)
print(type(chunk))
print(dir(chunk))
print(chunk)