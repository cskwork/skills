public class OrderService {

    public Order place(Cart cart, String couponCode) {
        Order order = new Order(cart.items());
        Coupon coupon = couponRepository.findLatest(cart.userId());
        order.applyDiscount(coupon.rate());
        return orderRepository.save(order);
    }
}
