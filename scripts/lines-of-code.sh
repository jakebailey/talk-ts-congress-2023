#!/usr/bin/zsh

versions=(
    v1.1
    v1.3
    v1.4
    v1.5.4
    v1.6.2
    v1.7.5
    v1.8.10
    v2.0.10
    v2.1.6
    v2.2.2
    v2.3.4
    v2.4.2
    v2.5.3
    v2.6.2
    v2.7.2
    v2.8.4
    v2.9.2
    v3.0.3
    v3.1.8
    v3.2.4
    v3.3.4000
    v3.4.5
    v3.5.3
    v3.6.5
    v3.7.7
    v3.8.3
    v3.9.10
    v4.0.8
    v4.1.6
    v4.2.4
    v4.3.5
    v4.4.4
    v4.5.5
    v4.6.4
    v4.7.4
    v4.8.4
    v4.9.5
    v5.0.4
    main
)

cd ~/work/TypeScript
for i in $versions; do
    git restore . &> /dev/null
    git clean -fdx . >& /dev/null
    git switch --detach $i >& /dev/null
    git restore . &> /dev/null
    git clean -fdx . >& /dev/null
    echo "[\"$i\", $(tokei --no-ignore-dot --no-ignore-parent --no-ignore-vcs --output json src | jq '.Total.code'), $(tokei --no-ignore-dot --no-ignore-parent --no-ignore-vcs --output json src/compiler/checker.ts | jq '.Total.code')],"
done
