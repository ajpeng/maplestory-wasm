#!/bin/bash

# MapleStory WASM Client Launcher
# This script starts all necessary services for the WASM frontend

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a port is in use
check_port() {
    local port=$1
    if lsof -ti:$port > /dev/null 2>&1; then
        return 0  # Port is in use
    else
        return 1  # Port is free
    fi
}

# Function to kill processes on specific ports
cleanup_ports() {
    local ports=("8000" "8080" "8765")
    
    for port in "${ports[@]}"; do
        if check_port $port; then
            print_warning "Killing existing process on port $port"
            lsof -ti:$port | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
    done
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Python virtual environment exists
    if [[ ! -d "venv" ]]; then
        print_error "Python virtual environment not found. Please run: python3 -m venv venv && source venv/bin/activate && pip install -r web/requirements.txt"
        exit 1
    fi
    
    # Check if WASM build exists
    if [[ ! -f "build/JourneyClient.js" ]] || [[ ! -f "build/JourneyClient.wasm" ]]; then
        print_error "WASM build not found. Please run: ./scripts/docker_build_wasm.sh"
        exit 1
    fi
    
    # Check if assets exist
    if [[ ! -d "assets" ]] || [[ -z "$(ls -A assets/)" ]]; then
        print_error "Assets directory is empty. Please convert .wz files to .nx format and place them in assets/"
        exit 1
    fi
    
    # Check if config exists
    if [[ ! -f "web/config.json" ]]; then
        print_error "web/config.json not found"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to start services
start_services() {
    print_status "Starting MapleStory WASM Client services..."
    
    # Clean up any existing processes
    cleanup_ports
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Start the main web server
    print_status "Starting web server on http://localhost:8000"
    python3 web/server.py > logs/web_server.log 2>&1 &
    WEB_SERVER_PID=$!
    
    # Wait a moment for server to start
    sleep 2
    
    # Start the WebSocket proxy  
    print_status "Starting WebSocket proxy on port 8080"
    python3 web/ws_proxy.py --ws-port 8080 > logs/ws_proxy.log 2>&1 &
    WS_PROXY_PID=$!
    
    # Start the assets server
    print_status "Starting assets server on port 8765"
    python3 web/assets_server.py --port 8765 --directory . > logs/assets_server.log 2>&1 &
    ASSETS_SERVER_PID=$!
    
    # Wait for services to start
    sleep 3
    
    # Check if services are running
    if check_port 8000 && check_port 8080 && check_port 8765; then
        print_success "All services started successfully!"
        echo
        print_status "MapleStory WASM Client is ready!"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}🍁 Open your browser and go to: ${BLUE}http://localhost:8000${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        echo -e "${YELLOW}Services running:${NC}"
        echo -e "  🌐 Web Server:     http://localhost:8000"
        echo -e "  🔌 WebSocket Proxy: ws://localhost:8080"  
        echo -e "  📁 Assets Server:   ws://localhost:8765"
        echo
        echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
        echo
        
        # Save PIDs for cleanup
        echo $WEB_SERVER_PID > /tmp/maplestory_wasm_web_server.pid
        echo $WS_PROXY_PID > /tmp/maplestory_wasm_ws_proxy.pid  
        echo $ASSETS_SERVER_PID > /tmp/maplestory_wasm_assets_server.pid
        
    else
        print_error "Failed to start one or more services. Check logs for details."
        cleanup_services
        exit 1
    fi
}

# Function to cleanup services
cleanup_services() {
    print_status "Stopping services..."
    
    # Kill by PID if available
    if [[ -f "/tmp/maplestory_wasm_web_server.pid" ]]; then
        kill $(cat /tmp/maplestory_wasm_web_server.pid) 2>/dev/null || true
        rm -f /tmp/maplestory_wasm_web_server.pid
    fi
    
    if [[ -f "/tmp/maplestory_wasm_ws_proxy.pid" ]]; then
        kill $(cat /tmp/maplestory_wasm_ws_proxy.pid) 2>/dev/null || true
        rm -f /tmp/maplestory_wasm_ws_proxy.pid
    fi
    
    if [[ -f "/tmp/maplestory_wasm_assets_server.pid" ]]; then
        kill $(cat /tmp/maplestory_wasm_assets_server.pid) 2>/dev/null || true
        rm -f /tmp/maplestory_wasm_assets_server.pid
    fi
    
    # Clean up any remaining processes on the ports
    cleanup_ports
    
    print_success "All services stopped"
}

# Function to show service status
show_status() {
    echo -e "${BLUE}MapleStory WASM Client Service Status:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if check_port 8000; then
        echo -e "🌐 Web Server (8000):     ${GREEN}RUNNING${NC}"
    else
        echo -e "🌐 Web Server (8000):     ${RED}STOPPED${NC}"
    fi
    
    if check_port 8080; then
        echo -e "🔌 WebSocket Proxy (8080): ${GREEN}RUNNING${NC}"
    else
        echo -e "🔌 WebSocket Proxy (8080): ${RED}STOPPED${NC}"
    fi
    
    if check_port 8765; then
        echo -e "📁 Assets Server (8765):   ${GREEN}RUNNING${NC}"
    else
        echo -e "📁 Assets Server (8765):   ${RED}STOPPED${NC}"
    fi
    echo
}

# Create logs directory
mkdir -p logs

# Handle script termination
trap cleanup_services SIGINT SIGTERM EXIT

# Main script logic
case "${1:-start}" in
    start)
        check_prerequisites
        start_services
        
        # Keep script running and show periodic status
        while true; do
            sleep 30
            if ! (check_port 8000 && check_port 8080 && check_port 8765); then
                print_error "One or more services have stopped unexpectedly"
                break
            fi
        done
        ;;
        
    stop)
        cleanup_services
        ;;
        
    status)
        show_status
        ;;
        
    restart)
        cleanup_services
        sleep 2
        check_prerequisites  
        start_services
        ;;
        
    *)
        echo "Usage: $0 {start|stop|status|restart}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all WASM client services (default)"
        echo "  stop    - Stop all services"
        echo "  status  - Show service status"
        echo "  restart - Restart all services"
        exit 1
        ;;
esac