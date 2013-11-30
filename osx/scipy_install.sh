# set up some taps and update brew
brew tap homebrew/science # a lot of cool formulae for scientific tools
brew tap samueljohn/python # numpy, scipy
brew update && brew upgrade

# install a brewed python
brew install python --with-brewed-openssl

# install openblas (otherwise scipy's arpack tests will fail)
brew install openblas

# install PIL, imagemagick, graphviz and other
# image generating stuff (qt is nice for viewing)
brew install pillow imagemagick graphviz
brew install cairo --without-x
brew install py2cairo # this will ask you to download xquartz and install it
brew install qt pyqt

# install nose (unittests & doctests on steroids)
pip install virtualenv nose

# install numpy and scipy
brew install numpy --with-openblas
brew install scipy --with-openblas

# test the scipy install
brew test scipy

# some cool python libs (if you don't know them, look them up)
# time series stuff, natural language toolkit
# generate plots, symbolic maths in python, fancy debugging output
pip install pandas nltk matplotlib sympy q

# ipython and notebook support
brew install zmq
pip install ipython[zmq,qtconsole,notebook,test]

# html stuff (parsing)
pip install html5lib cssselect pyquery lxml BeautifulSoup

# semantic web stuff: rdf & sparql
pip install rdflib SPARQLWrapper

# picloud (easily run python scripts in the cloud)
pip install cloud
