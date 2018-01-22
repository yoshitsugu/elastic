#!/bin/bash

set -o errexit -o nounset -o xtrace

if [ "$KIND" == "build" ] || [ "$KIND" == "local" ] ; then
    cargo test --verbose --all

    BRANCH=$(if [ "$KIND" == "local" ]; then echo "local"; elif [ "$TRAVIS_PULL_REQUEST" == "false" ]; then echo $TRAVIS_BRANCH; else echo $TRAVIS_PULL_REQUEST_BRANCH; fi)

    if [ "$BRANCH" == "vNext" ] || [ "$KIND" == "local" ] ; then
        cargo doc --no-deps --all

        if [ "$BRANCH" == "vNext" ] ; then
            echo "uploading crate docs"

            REV=$(git rev-parse --short HEAD)
            cd target/doc
            rm -rf .git || true
            git init
            git remote add upstream "https://$GH_TOKEN@github.com/elastic-rs/elastic.git"
            git config user.name "elastic-rs"
            git config user.email "travis@elastic.rs"
            git add -A .
            git commit -qm "Build docs at ${TRAVIS_REPO_SLUG}@${REV}"

            echo "Pushing gh-pages to GitHub"
            git push -q upstream HEAD:refs/heads/gh-pages --force
        fi
    fi
fi
if [ "$KIND" == "bench" ] || [ "$KIND" == "local" ] ; then
    cargo bench --verbose --all

    cargo build --manifest-path benches/Cargo.toml --all
fi
if [ "$KIND" == "integration" ] || [ "$KIND" == "local" ] ; then
    ELASTIC_INTEGRATION_LOG=debug

    cargo run --manifest-path tests/run/Cargo.toml -- --runs default sniffed_node --container-path tests/run/containers
fi
