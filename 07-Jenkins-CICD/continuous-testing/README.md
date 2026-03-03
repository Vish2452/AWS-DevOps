# Continuous Testing — Maven & Selenium

> Automated build management (Maven) and browser-based testing (Selenium). Ensure code quality through automated testing in CI/CD pipelines.

---

## Real-World Analogy

- **Maven** is like a **factory assembly line manager** — it knows the order of operations (compile → test → package → deploy), manages all the parts (dependencies), and produces a finished product (artifact)
- **Selenium** is like a **robot QA tester** — it opens a browser, clicks buttons, fills forms, and verifies results exactly like a human would, but 100x faster

---

## Part 1: Maven — Build Automation

### What is Maven?

```
Maven is a build automation tool for Java projects. It manages:
1. Project structure (standard layout)
2. Dependencies (download from Maven Central)
3. Build lifecycle (compile → test → package → deploy)
4. Plugins (extend functionality)
```

### Maven Build Lifecycle

```
┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│  validate  │───▶│  compile   │───▶│   test     │───▶│  package   │
│            │    │            │    │            │    │            │
│ Check POM  │    │ Java → .class│   │ Run JUnit  │    │ Create     │
│ is valid   │    │ files      │    │ tests      │    │ JAR/WAR    │
└────────────┘    └────────────┘    └────────────┘    └────────────┘
                                                            │
┌────────────┐    ┌────────────┐    ┌────────────┐         │
│   deploy   │◀───│  install   │◀───│  verify    │◀────────┘
│            │    │            │    │            │
│ Push to    │    │ Copy to    │    │ Integration│
│ remote repo│    │ local .m2  │    │ tests      │
└────────────┘    └────────────┘    └────────────┘
```

### POM.xml (Project Object Model)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">

    <modelVersion>4.0.0</modelVersion>

    <!-- Project coordinates -->
    <groupId>com.mycompany</groupId>
    <artifactId>my-web-app</artifactId>
    <version>1.0.0</version>
    <packaging>war</packaging>

    <!-- Properties -->
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <selenium.version>4.15.0</selenium.version>
        <junit.version>5.10.1</junit.version>
    </properties>

    <!-- Dependencies -->
    <dependencies>
        <!-- Selenium WebDriver -->
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-java</artifactId>
            <version>${selenium.version}</version>
        </dependency>

        <!-- Chrome WebDriver -->
        <dependency>
            <groupId>org.seleniumhq.selenium</groupId>
            <artifactId>selenium-chrome-driver</artifactId>
            <version>${selenium.version}</version>
        </dependency>

        <!-- WebDriverManager (auto-downloads driver binaries) -->
        <dependency>
            <groupId>io.github.bonigarcia</groupId>
            <artifactId>webdrivermanager</artifactId>
            <version>5.6.2</version>
        </dependency>

        <!-- JUnit 5 -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <version>${junit.version}</version>
            <scope>test</scope>
        </dependency>

        <!-- TestNG (alternative to JUnit) -->
        <dependency>
            <groupId>org.testng</groupId>
            <artifactId>testng</artifactId>
            <version>7.8.0</version>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <!-- Build plugins -->
    <build>
        <plugins>
            <!-- Surefire plugin for running tests -->
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.2.3</version>
                <configuration>
                    <includes>
                        <include>**/*Test.java</include>
                    </includes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### Essential Maven Commands

```bash
# Clean previous builds
mvn clean

# Compile source code
mvn compile

# Run unit tests
mvn test

# Package (create JAR/WAR)
mvn package

# Install to local repository (~/.m2)
mvn install

# Clean + Package (most common)
mvn clean package

# Skip tests during build
mvn clean package -DskipTests

# Run specific test class
mvn test -Dtest=LoginTest

# Run with specific profile
mvn clean package -P production

# Show dependency tree
mvn dependency:tree

# Check for dependency updates
mvn versions:display-dependency-updates
```

---

## Part 2: Selenium — Browser Automation & Testing

### What is Selenium?

```
Selenium automates web browsers. Components:
1. Selenium WebDriver — programmatic browser control (Java, Python, C#, etc.)
2. Selenium Grid — run tests in parallel across multiple machines/browsers
3. Selenium IDE — browser extension for record & playback (no code)
```

### Selenium Architecture

```
Test Code (Java/Python)
        │
        ▼
  WebDriver API
        │
        ▼
  Browser Driver           Browser Driver
  (chromedriver)           (geckodriver)
        │                       │
        ▼                       ▼
  ┌──────────┐           ┌──────────┐
  │  Chrome  │           │ Firefox  │
  └──────────┘           └──────────┘

Selenium Grid:
┌──────────────────────────────────────────┐
│              Selenium Hub                 │
│         (coordinates tests)              │
└──────────┬────────────┬─────────────────┘
           │            │
     ┌─────▼────┐ ┌────▼─────┐
     │  Node 1  │ │  Node 2  │
     │ Chrome   │ │ Firefox  │
     │ Linux    │ │ Windows  │
     └──────────┘ └──────────┘
```

### Selenium with Java (JUnit 5)

```java
import org.junit.jupiter.api.*;
import org.openqa.selenium.*;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import io.github.bonigarcia.wdm.WebDriverManager;

import static org.junit.jupiter.api.Assertions.*;

public class LoginTest {
    private WebDriver driver;

    @BeforeEach
    void setUp() {
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        // options.addArguments("--headless");  // Headless mode
        driver = new ChromeDriver(options);
        driver.manage().window().maximize();
    }

    @Test
    void testSuccessfulLogin() {
        // Navigate to login page
        driver.get("https://myapp.example.com/login");

        // Find elements and interact
        driver.findElement(By.id("username")).sendKeys("testuser");
        driver.findElement(By.id("password")).sendKeys("password123");
        driver.findElement(By.id("login-button")).click();

        // Wait for page load and verify
        WebElement welcomeMsg = driver.findElement(By.id("welcome-message"));
        assertEquals("Welcome, testuser!", welcomeMsg.getText());

        // Verify URL changed to dashboard
        assertTrue(driver.getCurrentUrl().contains("/dashboard"));
    }

    @Test
    void testFailedLogin() {
        driver.get("https://myapp.example.com/login");

        driver.findElement(By.id("username")).sendKeys("wronguser");
        driver.findElement(By.id("password")).sendKeys("wrongpass");
        driver.findElement(By.id("login-button")).click();

        // Verify error message
        WebElement error = driver.findElement(By.className("error-message"));
        assertEquals("Invalid credentials", error.getText());
    }

    @AfterEach
    void tearDown() {
        if (driver != null) {
            driver.quit();
        }
    }
}
```

---

## Headless Mode

> Run browser tests without a visible GUI. Essential for CI/CD pipelines (Jenkins, GitHub Actions) where there's no display.

```java
// Chrome Headless
ChromeOptions options = new ChromeOptions();
options.addArguments("--headless=new");       // New headless mode
options.addArguments("--no-sandbox");          // Required in Docker/CI
options.addArguments("--disable-dev-shm-usage"); // Prevent /dev/shm issues
options.addArguments("--window-size=1920,1080"); // Set viewport
options.addArguments("--disable-gpu");         // Disable GPU acceleration

WebDriver driver = new ChromeDriver(options);
```

```java
// Firefox Headless
FirefoxOptions options = new FirefoxOptions();
options.addArguments("--headless");
options.addArguments("--width=1920");
options.addArguments("--height=1080");

WebDriver driver = new FirefoxDriver(options);
```

**Why headless?**
- No display needed (CI/CD servers like Jenkins don't have a monitor)
- Faster execution (no rendering overhead)
- Lower resource usage
- Works in Docker containers

---

## Running Tests on Chrome WebDriver

### Project Structure

```
selenium-tests/
├── pom.xml
├── src/
│   ├── main/java/
│   │   └── com/mycompany/
│   │       └── App.java
│   └── test/java/
│       └── com/mycompany/
│           ├── LoginTest.java
│           ├── DashboardTest.java
│           └── SearchTest.java
└── testng.xml
```

### Running with Maven

```bash
# Run all tests
mvn clean test

# Run specific test class
mvn test -Dtest=LoginTest

# Run with headless mode (system property)
mvn test -Dheadless=true

# Run specific test method
mvn test -Dtest=LoginTest#testSuccessfulLogin

# Generate test report
mvn surefire-report:report
# Report at: target/site/surefire-report.html
```

---

## Real-Time Example 1: Selenium Tests in Jenkins Pipeline

**Scenario:** Run automated browser tests as part of a Jenkins CI/CD pipeline.

```groovy
// Jenkinsfile
pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk 'JDK-17'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/company/webapp.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean compile'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn test -Dtest="*UnitTest"'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Selenium Tests') {
            steps {
                sh '''
                    mvn test \
                        -Dtest="*SeleniumTest" \
                        -Dheadless=true \
                        -Dbrowser=chrome
                '''
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    publishHTML([
                        reportName: 'Selenium Report',
                        reportDir: 'target/site',
                        reportFiles: 'surefire-report.html'
                    ])
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
    }
}
```

---

## Real-Time Example 2: Headless Test with Chrome WebDriver

```java
import org.junit.jupiter.api.Test;
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import io.github.bonigarcia.wdm.WebDriverManager;

import java.time.Duration;
import static org.junit.jupiter.api.Assertions.*;

public class HeadlessSearchTest {

    @Test
    void testSearchFunctionality() {
        // Setup headless Chrome
        WebDriverManager.chromedriver().setup();
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--headless=new");
        options.addArguments("--no-sandbox");
        options.addArguments("--disable-dev-shm-usage");
        options.addArguments("--window-size=1920,1080");

        WebDriver driver = new ChromeDriver(options);
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

        try {
            // Navigate to search page
            driver.get("https://myapp.example.com");

            // Type search query
            WebElement searchBox = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.id("search-input"))
            );
            searchBox.sendKeys("DevOps Engineer");
            searchBox.submit();

            // Wait for results
            WebElement results = wait.until(
                ExpectedConditions.visibilityOfElementLocated(By.id("search-results"))
            );

            // Verify results appeared
            assertTrue(results.getText().contains("DevOps"));

            // Take screenshot (even in headless mode)
            // File screenshot = ((TakesScreenshot) driver).getScreenshotAs(OutputType.FILE);
            // FileUtils.copyFile(screenshot, new File("search-results.png"));

        } finally {
            driver.quit();
        }
    }
}
```

---

## Real-Time Example 3: Selenium Grid for Parallel Testing

**Scenario:** Run tests across Chrome, Firefox, and Edge simultaneously using Selenium Grid.

```bash
# Start Selenium Grid with Docker Compose
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  selenium-hub:
    image: selenium/hub:4.15.0
    ports:
      - "4442:4442"
      - "4443:4443"
      - "4444:4444"

  chrome:
    image: selenium/node-chrome:4.15.0
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=4

  firefox:
    image: selenium/node-firefox:4.15.0
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=4

  edge:
    image: selenium/node-edge:4.15.0
    shm_size: 2gb
    depends_on:
      - selenium-hub
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=4
EOF

docker-compose up -d
# Grid UI: http://localhost:4444/ui
```

```java
// Connect to Selenium Grid
import org.openqa.selenium.remote.RemoteWebDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import java.net.URL;

ChromeOptions options = new ChromeOptions();
WebDriver driver = new RemoteWebDriver(
    new URL("http://localhost:4444/wd/hub"),
    options
);
driver.get("https://myapp.example.com");
// Tests run on Grid node, not locally
```

---

## Maven + Selenium in CI/CD

```yaml
# GitHub Actions workflow for Selenium tests
name: Selenium Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      selenium-hub:
        image: selenium/standalone-chrome:4.15.0
        ports:
          - 4444:4444
        options: --shm-size=2gb

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven

      - name: Run Selenium tests
        run: |
          mvn clean test \
            -Dheadless=true \
            -Dwebdriver.remote.url=http://localhost:4444/wd/hub

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: target/surefire-reports/
```

---

## Labs

### Lab 1: Set Up Maven Project with Dependencies
```bash
# Install Maven
sudo apt-get install -y maven
mvn --version

# Create project from archetype
mvn archetype:generate \
    -DgroupId=com.mycompany \
    -DartifactId=selenium-tests \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DinteractiveMode=false

# Add Selenium and JUnit dependencies to pom.xml
# Run: mvn clean compile
# Run: mvn test
```

### Lab 2: Implement Headless Chrome Test
```bash
# Add Selenium and WebDriverManager dependencies
# Write a test that:
#   - Opens Chrome in headless mode
#   - Navigates to a website
#   - Searches for a term
#   - Verifies results
# Run: mvn test -Dheadless=true
# View report: target/surefire-reports/
```

### Lab 3: Integrate with Jenkins
```bash
# Set up Jenkins (Docker)
# Install Maven Integration plugin
# Create a pipeline job
# Write Jenkinsfile with Maven + Selenium stages
# Run pipeline
# View test results in Jenkins
```

### Lab 4: Run Tests on Selenium Grid
```bash
# Start Selenium Grid with Docker Compose
# Write tests that connect to Grid hub
# Run parallel tests across Chrome and Firefox
# View Grid UI at localhost:4444
# Monitor test distribution across nodes
```

---

## Interview Questions

1. **What is Maven?**
   → Java build automation tool. Manages project structure, dependencies, build lifecycle (compile → test → package → deploy), and plugins. Uses pom.xml for configuration.

2. **Explain Maven build lifecycle phases.**
   → validate → compile → test → package → verify → install → deploy. Each phase runs all previous phases. `mvn package` runs validate through package.

3. **What is POM.xml?**
   → Project Object Model — Maven's configuration file. Contains project coordinates (groupId, artifactId, version), dependencies, plugins, profiles, and build settings.

4. **What is Selenium and its components?**
   → Browser automation framework. WebDriver (programmatic control), Grid (parallel testing across browsers/machines), IDE (record/playback browser extension).

5. **What is headless mode in Selenium?**
   → Running browser without visible GUI. Used in CI/CD pipelines where no display is available. Same Selenium API, just with `--headless` argument. Faster execution.

6. **How do you run Selenium tests in a CI/CD pipeline?**
   → Use headless Chrome/Firefox, Maven Surefire plugin for test execution, Selenium Grid (Docker) for parallel testing. Publish JUnit XML reports for visibility.

7. **What is Selenium Grid?**
   → Distributed test execution. Hub receives test requests and routes to available Nodes. Nodes run different browsers (Chrome, Firefox, Edge). Enables parallel and cross-browser testing.

8. **How does Maven manage dependencies?**
   → Dependencies declared in pom.xml. Maven downloads from Maven Central (or configured repos) to local `.m2` repository. Transitive dependencies resolved automatically. Scope controls usage (compile, test, runtime).
