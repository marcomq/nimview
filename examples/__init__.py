import sys, os, pathlib
# print(pathlib.Path(os.path.abspath(__file__)).parent.parent)
sys.path.append(str(pathlib.Path(os.path.abspath(__file__)).parent.parent) + "/out")
import nimview