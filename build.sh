#!/bin/sh
set -e

PYTHON=python2.7
SRCDIR=$PWD/pypi
EGGDIR=$SRCDIR/eggs

# OpenBSD gcc doesn't search /usr/local/include by default
CFLAGS=-I/usr/local/include; export CFLAGS

mkdir -p $EGGDIR
cd $SRCDIR

build () {
    pkg=$1
    build_cmd=$2
    [ -z "$build_cmd" ] && build_cmd="$PYTHON setup.py bdist_egg"
    if [ -e .$pkg.built ]; then
        echo "Skipping already built $pkg"
        return
    fi
    echo "Building $pkg"
    tar -xzf $pkg.tar.gz
    if (cd $pkg && $build_cmd && mv dist/*.egg $EGGDIR/) > $pkg.log 2>&1; then
        rm -rf $pkg
        touch .$pkg.built
    else
        echo "Failed (exit $?; see $SRCDIR/$pkg.log)"
        return 1
    fi
}

# For build-time dependencies, we install to the user's home dir
# (~/.local/lib/pythonX.Y/site-packages) as well as saving the eggs for easier
# installation later.
build_bdep () {
    $PYTHON setup.py bdist_egg
    $PYTHON setup.py install --user
}

# Bare distutils don't support eggs; patch in setuptools
build_distutils () {
    $PYTHON -c "import setuptools; __file__='setup.py'; execfile('setup.py')" bdist_egg
}


###########################################################################
# The following packages are required only at build time (setup_requires) #
###########################################################################

# Required by jsonschema
build vcversioner-2.16.0.0 build_bdep

# Required by pytest-runner (thus must be installed first)
build setuptools_scm-1.11.1 build_bdep

# Required by lots of packages (if you wanted to actually run the tests, you'd
# also need pytest). Don't worry about "your setuptools is too old (<12)",
# assuming the build succeeds. This comes from setuptools_scm, which extracts
# version numbers from SCM metadata; it doesn't need to do that here as the
# number is baked into the source distribution.
build pytest-runner-2.9 build_bdep


##########################################################################
# The following packages are also required at runtime (install_requires) #
##########################################################################

# Required by cffi (thus must be installed first)
build_pycparser () {
    # pycparser bundles precompiled lex/yacc parsing tables and Python
    # bytecode: effectively, binary blobs. To ensure they really come from the
    # purported sources, we delete and regenerate them.
    find . -iname '*.pyc' -exec rm {} +
    cd pycparser
    rm -f c_ast.py lextab.py yacctab.py
    $PYTHON _build_tables.py
    cd ..
    build_bdep
}
build pycparser-2.14 build_pycparser

# Required by the secp256k1 bindings
build cffi-1.7.0 build_bdep


##############################################################################
# The remaining packages are only required at runtime (order doesn't matter) #
##############################################################################

# SQLAlchemy ORM
build_sqlalchemy () {
    # Disable C optimizations pending vetting of the code
    DISABLE_SQLALCHEMY_CEXT=1 $PYTHON setup.py bdist_egg
}
build SQLAlchemy-1.0.14 build_sqlalchemy

# Flask web "microframework"
build Flask-0.10.1
build Werkzeug-0.11.10
build Jinja2-2.8
build MarkupSafe-0.23
build itsdangerous-0.24

# Flask extensions
build Flask-Cors-2.1.2
build six-1.10.0
build Flask-Login-0.3.2
build flask-bitjws-0.1.1.5

# JSON Web Signing with Bitcoin signatures
build bitjws-0.6.3.1
build base58-0.2.3
# For this package you MUST use the correct version corresponding to the
# secp256k1 checkout. Don't worry about gcc fatal errors for ecdh and schnorr
# headers; we didn't build these modules as bitjws doesn't use them.
build secp256k1-0.11.0

# alchemyjsonschema: generates JSON Schema docs from SQLAlchemy models
build alchemyjsonschema-0.3.3
build jsonschema-2.5.1
build repoze.lru-0.6
build functools32-3.2.3-2 build_distutils
build strict-rfc3339-0.7 build_distutils
build isodate-0.5.4
build pytz-2016.6.1

# Green Unicorn WSGI application server
build gunicorn-19.6.0

# Currency plugin dependencies
build pycoin-0.62
build python-bitcoinrpc-0.3 build_distutils
