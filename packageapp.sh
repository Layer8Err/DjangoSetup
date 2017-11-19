#!/bin/bash
# You should have activated the virtual environment
# source bin/activate
# You should be in the root django project (site)
# directory
# The packaging will be handled using setuptools
################################################################################
## Config variables
virtenv=/opt/djangvenv
project=djangsite
targetapp=polls
################################################################################
## Build Directory:
builddir=django-${targetapp}

cd ${virtenv}
echo "Creating app build directory..."
mkdir ${virtenv}/${builddir}
echo "Moving production app into build directory..."
mv -f -v ${virtenv}/${project}/${targetapp} ${virtenv}/${builddir}

echo "Creating README.rst file (fill this out before final packaging)..."
touch ${virtenv}/${builddir}/README.rst
################################################################################

echo "Filling README.rst with lorem ipsum stuff..."
read -d '' readmerst <<"EOF"
=======
appname
=======

appname is a Django app to <description of what app does>.

Detailed documentation is in the "docs" directory.

Quick start
-----------

1. Add "appname" to your INSTALLED_APPS setting like this::

    INSTALLED_APPS = [
        ...
        'appname',
    ]

2. Include the appname URLconf in your project urls.py like this::

    url(r'^appname/', include('appname.urls')),

3. Run `python manage.py migrate` to create the appname models.

4. Start the development server and visit http://127.0.0.1:8000/admin/
   to create an entry (you'll need the Admin app enabled).

5. Visit http://127.0.0.1:8000/appname/ to participate in the poll.
EOF
echo "$readmerst" >> ${virtenv}/${builddir}/README.rst
sed -i s/appname/${targetapp}/g ${virtenv}/${builddir}/README.rst
################################################################################

echo "Creating LICENSE file..."
touch ${virtenv}/${builddir}/README.rst
echo "Filling with MIT license text... please modify to suit your needs"
read -d '' license <<"EOF"
MIT License

Copyright (c) <YEAR> <DISTRIBUTOR>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantialto lowercase portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF
echo "$license" >> ${virtenv}/${builddir}/LICENSE
################################################################################

echo "Creating setup.py..."
touch ${virtenv}/${builddir}/setup.py
read -d '' setuppy <<"EOF"
import os
from setuptools import find_packages, setup

with open(os.path.join(os.path.dirname(__file__), 'README.rst')) as readme:
    README = readme.read()

# allow setup.py to be run from any path
os.chdir(os.path.normpath(os.path.join(os.path.abspath(__file__), os.pardir)))

setup(
    name='builddir',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    license='MIT License',  # example license
    description='A Django app to do stuff.',
    long_description=README,
    url='https://www.example.com/',
    author='Your Name',
    author_email='yourname@example.com',
    classifiers=[
        'Environment :: Web Environment',
        'Framework :: Django',
        'Framework :: Django :: X.Y',  # replace "X.Y" as appropriate
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',  # example license
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        # Replace these appropriately if you are stuck on Python 2.
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Topic :: Internet :: WWW/HTTP',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
    ],
)
EOF
echo "$setuppy" >> ${virtenv}/${builddir}/setup.py
sed -i s/builddir/${builddir}/g ${virtenv}/${builddir}/setup.py
################################################################################

echo "Creating MANIFEST.in file for additional includes..."
touch ${virtenv}/${builddir}/MANIFEST.in
read -d '' manifest <<"EOF"
include LICENSE
include README.rst
recursive-include appname/static *
recursive-include appname/templates *
recursive-include appname/docs *
EOF
echo "$manifest" >> ${virtenv}/${builddir}/MANIFEST.in
sed -i s/appname/${targetapp}/g ${virtenv}/${builddir}/MANIFEST.in
################################################################################

echo "Creating docs folder for additional documentation..."
mkdir ${virtenv}/${builddir}/docs
################################################################################

echo "========================================="
echo -n "Ready to build package? [Y/n]: "
read -r buildit
if [ ! "$buildit" ]; then
    buildit="y"
fi
buildit=$(echo $buildit | tr [:upper:] [:lower:])
buildit=${buildit:0:1}
if [ "$buildit" != "y" ]; then
    exit
fi
echo "-----------------------------------------"
echo "Building package..."
cd ${virtenv}/${builddir}
echo "Activating virtual environment..."
source ${virtenv}/bin/activate
python3 setup.py sdist

echo "========================================="
echo -n "Re-install package? [y/N]: "
read -r reinstall
if [ ! "$reinstall" ]; then
    reinstall="n"
fi
reinstall=$(echo $reinstall | tr [:upper:] [:lower:])
reinstall=${reinstall:0:1}
if [ "$reinstall" != "y" ]; then
    deactivate
    exit
fi
if [ "$reinstall" == "y"]; then
    echo "-----------------------------------------"
    echo "Re-installing ${targetapp} with pip..."
    cd ${virtenv}/${builddir}
    #pip3 install --user dist/${builddir}-0.1.tar.gz # use if not in virtenv
    pip3 install dist/${builddir}-0.1.tar.gz
    deactivate
fi

################################################################################
## Testing Stuff ##
# Uninstall package
# pip3 uninstall ${builddir}

## Installing on other systems
# Don't forget to collectstatic/migrate after pip install
# Make sure that you add the app to the enabled apps (settings.py)
# 'targetapp.apps.TargetAppConfig'
# Make sure that you modify the urls.py file
# from django.conf.urls import url, include
# url(r'^', include('targetapp.urls')),
