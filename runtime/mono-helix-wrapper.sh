#! /bin/sh
r="$(pwd)"
MONO_CFG_DIR="$r/runtime/etc"
PATH="$r/runtime/_tmpinst/bin:$PATH"
MONO_EXECUTABLE=${MONO_EXECUTABLE:-"$r/mono-sgen"}
MONO_PATH="$r:$r/tests"
export MONO_CFG_DIR MONO_PATH PATH
chmod +x "${MONO_EXECUTABLE}"

"${MONO_EXECUTABLE}" --version

if [ $? -ne 0 ]; then  # this can happen when running the i386 binary on amd64 and the i386 packages aren't installed
    sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt install -y libc6-i386 lib32gcc1
fi

if [ "$1" = "run-bcl-tests" ]; then
    if [ "$2" = "xunit" ]; then
        export REMOTE_EXECUTOR="$r/RemoteExecutorConsoleApp.exe"
        "${MONO_EXECUTABLE}" --config "$r/runtime/etc/mono/config" --debug xunit.console.exe "tests/$3" -noappdomain -noshadow -parallel none -xml testResults.xml -notrait category=failing -notrait category=nonmonotests -notrait Benchmark=true -notrait category=outerloop -notrait category=nonlinuxtests
        exit $?
    elif [ "$2" = "nunit" ]; then
        MONO_REGISTRY_PATH="$HOME/.mono/registry" MONO_TESTS_IN_PROGRESS="yes" "${MONO_EXECUTABLE}" --config "$r/runtime/etc/mono/config" --debug nunit-lite-console.exe "tests/$3" -format:xunit -result:testResults.xml
        exit $?
    else
        echo "Unknown test runner."
        exit 1
    fi
fi
