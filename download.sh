#!/bin/sh
set -e

get () {
    url="$1"
    filename="$2"
    if [ -z "$filename"]; then
        filename=`basename "$url"`
    fi
    if [ -e "$filename" ]; then
        echo "$filename exists, skipping"
    else
        echo "Downloading $url"
        curl -o "$filename" "$url"
        #ftp -o "$filename" "$url" # OpenBSD
    fi
}

mkdir -p pypi
cd pypi

PYPI=https://pypi.python.org/packages

# If any of these go bad, please notify the Git Guild and we will update the
# links or supply the files as appropriate.

get $PYPI/6c/c5/14260ba32c715d679a0d40daa18299a3c571f5af6fa57be4a6bc3afee72c/alchemyjsonschema-0.3.3.tar.gz
get $PYPI/32/8c/9b8b1b8364a945fa1ed4308d650880a5eb77bd08c2086e32e1f608440ed8/base58-0.2.3.tar.gz
get $PYPI/e2/18/aa38241c9f377749a44584941200304f57c6777aaa81bdec5fa3ec5e8eeb/bitjws-0.6.3.1.tar.gz
get $PYPI/83/3c/00b553fd05ae32f27b3637f705c413c4ce71290aa9b4c4764df694e906d9/cffi-1.7.0.tar.gz
get $PYPI/db/9c/149ba60c47d107f85fe52564133348458f093dd5e6b57a5b60ab9ac517bb/Flask-0.10.1.tar.gz
get $PYPI/81/f9/1200a572f2ddbc1016a4d524652432c68e12dbb065894016ee543cb5582c/flask-bitjws-0.1.1.5.tar.gz
get $PYPI/99/c3/a65908bc5a031652248dfdb1fd4814391e7b8efca704a94008d764c45292/Flask-Cors-2.1.2.tar.gz
get $PYPI/06/e6/61ed90ed8ce6752b745ed13fac3ba407dc9db95dfa2906edc8dd55dde454/Flask-Login-0.3.2.tar.gz
get $PYPI/c5/60/6ac26ad05857c601308d8fb9e87fa36d0ebf889423f47c3502ef034365db/functools32-3.2.3-2.tar.gz
get $PYPI/84/ce/7ea5396efad1cef682bbc4068e72a0276341d9d9d0f501da609fab9fcb80/gunicorn-19.6.0.tar.gz
get $PYPI/f4/5b/fe03d46ced80639b7be9285492dc8ce069b841c0cebe5baacdd9b090b164/isodate-0.5.4.tar.gz
get $PYPI/dc/b4/a60bcdba945c00f6d608d8975131ab3f25b22f2bcfe1dab221165194b2d4/itsdangerous-0.24.tar.gz
get $PYPI/f2/2f/0b98b06a345a761bec91a079ccae392d282690c2d8272e708f4d10829e22/Jinja2-2.8.tar.gz
get $PYPI/58/0d/c816f5ea5adaf1293a1d81d32e4cdfdaf8496973aa5049786d7fdb14e7e7/jsonschema-2.5.1.tar.gz
get $PYPI/c0/41/bae1254e0396c0cc8cf1751cb7d9afc90a602353695af5952530482c963f/MarkupSafe-0.23.tar.gz
get $PYPI/7b/a8/dc2d50a6f37c157459cd18bab381c8e6134b9381b50fbe969997b2ae7dbc/psycopg2-2.6.2.tar.gz
get $PYPI/73/62/75bca0408bdec63429f7008d8c8358a5bd929da65af3552ba35378263d1b/pycoin-0.62.tar.gz
get $PYPI/6d/31/666614af3db0acf377876d48688c5d334b6e493b96d21aa7d332169bee50/pycparser-2.14.tar.gz
get $PYPI/11/d4/c335ddf94463e451109e3494e909765c3e5205787b772e3b25ee8601b86a/pytest-runner-2.9.tar.gz
get $PYPI/61/f8/2c9fcdf8fce397c2c56a3166b619fe0608460cffec40bc99d84d02cbdd02/python-bitcoinrpc-0.3.tar.gz
get $PYPI/5d/8e/6635d8f3f9f48c03bb925fab543383089858271f9cfd1216b83247e8df94/pytz-2016.6.1.tar.gz
get $PYPI/6e/1e/aa15cc90217e086dc8769872c8778b409812ff036bf021b15795638939e4/repoze.lru-0.6.tar.gz
get $PYPI/ac/43/b7412740835674c406be622eb6e1703bc0a7bcf782aec022c8091c93e3fb/secp256k1-0.11.0.tar.gz
get $PYPI/84/aa/c693b5d41da513fed3f0ee27f1bf02a303caa75bbdfa5c8cc233a1d778c4/setuptools_scm-1.11.1.tar.gz
get $PYPI/b3/b2/238e2590826bfdd113244a40d9d3eb26918bd798fc187e2360a8367068db/six-1.10.0.tar.gz
get $PYPI/aa/cb/e3990b9da48facbe48b80a281a51fb925ff84aaaca44d368d658b0160fcf/SQLAlchemy-1.0.14.tar.gz
get $PYPI/56/e4/879ef1dbd6ddea1c77c0078cd59b503368b0456bcca7d063a870ca2119d3/strict-rfc3339-0.7.tar.gz
get $PYPI/c5/cc/33162c0a7b28a4d8c83da07bc2b12cee58c120b4a9e8bba31c41c8d35a16/vcversioner-2.16.0.0.tar.gz
get $PYPI/b7/7f/44d3cfe5a12ba002b253f6985a4477edfa66da53787a2a838a40f6415263/Werkzeug-0.11.10.tar.gz
