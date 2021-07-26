## Nimview Python sample application

This is using nakefiles to build the python library
- nake pyLib

The pyTest.py doesn't trigger start yet - so it doesn't opens a GUI yet. 
Currently only used for testing

building
nake
python bdist_wheel.py bdist_wheel
python setup.py 
python -m twine upload --repository pypi .\dist\nimview-0.2.3.*