# AurumHarmony Full Stack Installation Checklist

## 1. Python & pip
- Download and install Python 3.8+ from https://www.python.org/downloads/
- Ensure 'Add Python to PATH' is checked during installation.
- Verify installation:
  ```sh
  python --version
  pip --version
  ```

## 2. Docker & Docker Compose
- Download and install Docker Desktop: https://www.docker.com/products/docker-desktop
- Verify installation:
  ```sh
  docker --version
  docker-compose --version
  ```

## 3. Kubernetes
- Docker Desktop includes Kubernetes (enable in settings), or install Minikube: https://minikube.sigs.k8s.io/docs/
- Verify installation:
  ```sh
  kubectl version --client
  ```

## 4. Flutter
- Download and install Flutter: https://docs.flutter.dev/get-started/install
- Add Flutter to PATH.
- Verify installation:
  ```sh
  flutter --version
  ```

## 5. Node.js & npm (for React frontend)
- Download and install Node.js (includes npm): https://nodejs.org/
- Verify installation:
  ```sh
  node --version
  npm --version
  ```

## 6. Java (for Fabric tools)
- Download and install Java JDK 8+: https://adoptium.net/
- Verify installation:
  ```sh
  java -version
  ```

## 7. Go (for Fabric chaincode)
- Download and install Go: https://go.dev/doc/install
- Add Go to PATH.
- Verify installation:
  ```sh
  go version
  ```

## 8. Hyperledger Fabric Binaries
- Download Fabric samples, binaries, and Docker images:
  ```sh
  curl -sSL https://bit.ly/2ysbOFE | bash -s
  ```
- Add 'bin/' directory to PATH.
- Verify installation:
  ```sh
  cryptogen version
  configtxgen version
  peer version
  ```

## 9. Python Dependencies
- In your project root, install Python dependencies:
  ```sh
  python -m pip install -r requirements.txt
  ```

---

**Tip:** After installing, restart your terminal or computer to ensure all PATH changes take effect. 