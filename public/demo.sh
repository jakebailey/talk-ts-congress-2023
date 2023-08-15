#!/bin/sh

set -eo pipefail

WORKING=ts-module-conversion-demo

echo "This will create a new directory '$WORKING' and run the TypeScript module conversion."
read -p "Are you ready? [Y/n] " answer
case ${answer:0:1} in
    n|N )
        exit 1
    ;;
esac

if [ -d $WORKING ]; then
    read -p "$WORKING already exists; remove it? [Y/n] " answer
    case ${answer:0:1} in
        n|N )
            exit 1
        ;;
    esac
    rm -rf $WORKING
fi

mkdir $WORKING
cd $WORKING

echo Cloning the typeformer...
git clone --depth=1 https://github.com/jakebailey/typeformer.git >/dev/null 2>&1

echo Building the typeformer...
cd typeformer
npm ci >/dev/null 2>&1
npm run build >/dev/null 2>&1
cd ..

echo Cloning TypeScript pre-modules...
mkdir TypeScript
cd TypeScript
git init >/dev/null 2>&1
git remote add origin https://github.com/microsoft/TypeScript.git >/dev/null 2>&1
git fetch --depth 1 origin d83a5e1281379da54221fe39d5c0cb6ef4d1c109 >/dev/null 2>&1
git checkout FETCH_HEAD >/dev/null 2>&1
git switch -c main >/dev/null 2>&1
cd ..

echo Running the conversion...
cd TypeScript
node ../typeformer/dist/cli.js run

echo
echo "Yay, we're modules! Let's try building tsc..."

echo
echo "$ npx hereby tsc"
npx hereby tsc
echo "Wow, that fast?"

echo
echo "$ node ./built/local/tsc.js --version"
node ./built/local/tsc.js --version

echo
echo "It works!"
