#!/bin/bash

# BangoCat Test Runner Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_header() { echo -e "${WHITE}$1${NC}"; }
print_test() { echo -e "${CYAN}🧪 $1${NC}"; }

# Function to show usage
show_usage() {
    echo "BangoCat Test Runner"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose     Show verbose test output"
    echo "  -c, --coverage    Show code coverage information (requires code coverage tools)"
    echo "  -q, --quiet       Quiet mode - only show results"
    echo "  -f, --filter      Filter tests by name pattern"
    echo "  -h, --help        Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                        # Run all tests"
    echo "  $0 --verbose             # Run tests with verbose output"
    echo "  $0 --filter StrokeCounter # Run only StrokeCounter tests"
    echo "  $0 --coverage            # Run tests with coverage report"
}

# Parse command line arguments
VERBOSE=false
COVERAGE=false
QUIET=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -f|--filter)
            FILTER="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Get to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

print_header "🧪 BangoCat Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$QUIET" = false ]; then
    print_info "Project root: $PROJECT_ROOT"
    print_info "Running tests..."
    echo ""
fi

# Check if build is needed
if [ ! -d ".build" ] || [ "Sources/" -nt ".build" ]; then
    if [ "$QUIET" = false ]; then
        print_info "Building project first..."
    fi

    if [ "$VERBOSE" = true ]; then
        swift build --configuration debug
    else
        swift build --configuration debug > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then
        if [ "$QUIET" = false ]; then
            print_success "Build completed successfully"
        fi
    else
        print_error "Build failed! Fix build errors before running tests."
        exit 1
    fi
fi

# Prepare test command
TEST_CMD="swift test"

if [ "$VERBOSE" = true ]; then
    TEST_CMD="$TEST_CMD --verbose"
fi

if [ -n "$FILTER" ]; then
    TEST_CMD="$TEST_CMD --filter $FILTER"
    if [ "$QUIET" = false ]; then
        print_info "Filtering tests with pattern: $FILTER"
    fi
fi

# Add parallel execution for faster tests
TEST_CMD="$TEST_CMD --parallel"

# Run tests
if [ "$QUIET" = false ]; then
    print_test "Executing test suite..."
    echo ""
fi

START_TIME=$(date +%s)

if [ "$VERBOSE" = true ] || [ "$QUIET" = false ]; then
    eval $TEST_CMD
    TEST_RESULT=$?
else
    eval $TEST_CMD > /tmp/bangocat_test_output.txt 2>&1
    TEST_RESULT=$?
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Parse test results
if [ $TEST_RESULT -eq 0 ]; then
    print_success "All tests passed! 🎉"
else
    print_error "Some tests failed!"

    if [ "$QUIET" = true ]; then
        echo ""
        print_info "Test output:"
        cat /tmp/bangocat_test_output.txt
    fi
fi

# Show test summary
if [ "$QUIET" = false ]; then
    echo ""
    print_info "Test Summary:"
    echo "  • Duration: ${DURATION}s"
    echo "  • Filter: ${FILTER:-"None (all tests)"}"
    echo "  • Mode: $([ "$VERBOSE" = true ] && echo "Verbose" || echo "Standard")"
fi

# Coverage report
if [ "$COVERAGE" = true ]; then
    echo ""
    print_info "Generating coverage report..."

    # Check if llvm-cov is available
    if command -v llvm-cov >/dev/null 2>&1; then
        print_warning "Code coverage requires additional setup with llvm-cov"
        print_info "To enable coverage:"
        echo "  1. swift test --enable-code-coverage"
        echo "  2. xcrun llvm-cov show .build/debug/BangoCatPackageTests.xctest/Contents/MacOS/BangoCatPackageTests -instr-profile .build/debug/codecov/default.profdata Sources/"
    else
        print_warning "llvm-cov not found. Coverage reporting not available."
        print_info "Install with: xcode-select --install"
    fi
fi

# Show individual test file results (if available)
if [ "$QUIET" = false ] && [ -f "/tmp/bangocat_test_output.txt" ]; then
    echo ""
    print_info "Test Results by File:"

    # Extract test results for each file
    if grep -q "StrokeCounterTests" /tmp/bangocat_test_output.txt; then
        STROKE_TESTS=$(grep -c "StrokeCounterTests.*passed" /tmp/bangocat_test_output.txt || echo "0")
        echo "  • StrokeCounterTests: ${STROKE_TESTS} tests"
    fi

    if grep -q "CatAnimationControllerTests" /tmp/bangocat_test_output.txt; then
        ANIMATION_TESTS=$(grep -c "CatAnimationControllerTests.*passed" /tmp/bangocat_test_output.txt || echo "0")
        echo "  • CatAnimationControllerTests: ${ANIMATION_TESTS} tests"
    fi

    if grep -q "AppDelegateTests" /tmp/bangocat_test_output.txt; then
        DELEGATE_TESTS=$(grep -c "AppDelegateTests.*passed" /tmp/bangocat_test_output.txt || echo "0")
        echo "  • AppDelegateTests: ${DELEGATE_TESTS} tests"
    fi
fi

# Clean up temporary files
rm -f /tmp/bangocat_test_output.txt

echo ""
if [ $TEST_RESULT -eq 0 ]; then
    print_success "Test run completed successfully! ✨"
    print_info "Next steps:"
    echo "  • Run with --verbose for detailed output"
    echo "  • Use --filter to run specific test suites"
    echo "  • Check Scripts/README.md for more testing options"
else
    print_error "Test run completed with failures!"
    print_info "Debugging tips:"
    echo "  • Run with --verbose to see detailed error output"
    echo "  • Check individual test files in Tests/BangoCatTests/"
    echo "  • Ensure all dependencies are properly installed"
    exit 1
fi

echo ""
print_header "🐱 Happy testing! Remember: Good tests make good software!"