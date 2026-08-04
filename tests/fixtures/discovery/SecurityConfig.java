import org.springframework.security.web.SecurityFilterChain;
import org.springframework.boot.test.context.SpringBootTest;
import org.testcontainers.junit.jupiter.Testcontainers;

// spring-boot-starter-security on the classpath
@Testcontainers
@SpringBootTest
class SecurityConfigTest {
    SecurityFilterChain chain() { return null; }
}
