#!/bin/bash

pushd $(dirname $0) > /dev/null

ROOT="$1/"
DOCS_ROOT=$ROOT/doc/mkdocs

cd $(pwd -P)/..

doc_count=0
missing_count=0

function check_index {
    doc=${1/$ROOT/}
    line=$(grep "$doc" $DOCS_ROOT/mkdocs.yml)

    if [ -f "$1" ] && [ -z "$line" ]; then
        [[ 0 -eq $missing_count ]] && echo "Docs missing from the mkdocs.yml index:"
        ((missing_count+=1))
        echo "$missing_count: '$1'"
    fi
}

default_docs=$(find {scripts,doc,core,applications} \( -path 'doc/mkdocs' -o -path 'applications/*/doc/ref' -o -path 'core/*/doc/ref' \) -prune -o -type f -regex ".+\.md$")
doclist="${CHANGED_DOCS-${default_docs}}"
docs=""
for file in $doclist ; do
    case $file in
        doc/mkdocs|doc/mkdocs/*)
            ;;
        applications/*/doc/ref|applications/*/doc/ref/*)
            ;;
        core/*/doc/ref|core/*/doc/ref/*)
            ;;
        *.md)
            if [ -n "$doc" ]; then
                docs="$doc $file"
            else
                docs="$(realpath $file)"
            fi
            ;;
        *)
            ;;
    esac
done

for doc in $docs; do
    ((doc_count+=1))
    check_index $doc
done

if [[ 0 -lt $missing_count ]]; then
    ratio=$((100 * $missing_count / $doc_count))
    echo "Missing $missing_count / $doc_count: $ratio%"
    popd > /dev/null
    exit 1
fi

popd > /dev/null
