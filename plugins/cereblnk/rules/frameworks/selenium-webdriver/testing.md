---
name: selenium-webdriver-testing
genre: constraint
category: frameworks
paths:
  - "**/selenium/**/*.java"
  - "**/*WebDriverTest.java"
  - "**/*SeleniumTest.java"
---

# Selenium WebDriver Testing

Judgment lives in `skills/frameworks/selenium-webdriver/`.
The wider testing layer lives in [`../../common/testing.md`](../../common/testing.md).

## Waiting

- Every wait is an explicit condition on observable state
- Timeouts are named constants, chosen per condition

```java
new WebDriverWait(driver, TIMEOUT)
    .until(ExpectedConditions.textToBe(By.id("status"), "Settled"));
```

Avoid: a fixed sleep standing in for a condition. An implicit wait
combined with explicit waits in one suite.

## Locators

- Elements are located by a stable, test-owned attribute
- Locators live in a page object, never inline in a test

```java
final class PaymentPage {
    private static final By CAPTURE = By.cssSelector("[data-test=capture]");
    private static final By STATUS = By.id("status");
}
```

Avoid: an XPath that walks the layout. A selector bound to a class that
styling owns.

## Session lifecycle

- Each test gets its own driver and closes it in teardown
- Browser options are declared in one factory

```java
@BeforeEach
void start() {
    driver = DriverFactory.create();
}

@AfterEach
void quit() {
    driver.quit();
}
```

Avoid: a driver shared across tests. Options copied between test
classes and drifting apart.

## Failure evidence

- A failed run captures a screenshot and the page source
- The captured artefacts name the test that produced them

```java
Path dir = Path.of("build", "selenium-failures");
Files.createDirectories(dir);

Files.write(dir.resolve(testName + ".png"),
            ((TakesScreenshot) driver).getScreenshotAs(BYTES));
Files.writeString(dir.resolve(testName + ".html"),
                  driver.getPageSource());
```

Avoid: a failure reported as a bare timeout. Evidence overwritten by
the next failing test.

## Trigger table

| Seen in the diff | Section |
|---|---|
| a wait or sleep | Waiting |
| a By locator | Locators |
| driver setup or teardown | Session lifecycle |
| a failing run or a report | Failure evidence |
