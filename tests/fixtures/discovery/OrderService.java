package com.acme.orders;

import org.springframework.stereotype.Service;
import org.springframework.data.jpa.repository.Query;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.kafka.annotation.KafkaListener;

@Entity
class Order {
    @jakarta.persistence.ManyToOne(fetch = FetchType.EAGER)
    Customer customer;
}

@Service
class OrderService {
    @Query("select o from Order o where o.status = :s")
    java.util.List<Order> byStatus(String s);

    @PreAuthorize("hasRole('ADMIN')")
    void cancel(long id) { }

    @KafkaListener(topics = "orders")
    void onEvent(String payload) { }
}

// repository layer
import org.springframework.data.jpa.repository.JpaRepository;
import org.junit.jupiter.api.Test;
interface OrderRepo extends JpaRepository<Order, Long> { }
