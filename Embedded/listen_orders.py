"""
Script theo dõi danh sách đơn hàng theo thời gian thực.
Chạy: python Embedded/listen_orders.py
"""

from typing import List

from firebase_sample import FirebaseClient, Order


def print_orders(orders: List[Order], payload: dict, event_type: str) -> None:
    print("=" * 60)
    print(f"Event: {event_type}")
    print(f"Payload: {payload}")
    print(f"Tổng số đơn hàng: {len(orders)}")
    for order in orders:
        print(
            f"- {order.id}: {order.receiverName} ({order.status}) | "
            f"{order.goods} | {order.createdAt}"
        )


def log_error(exc: Exception) -> None:
    print(f"[ERROR] {exc}")


if __name__ == "__main__":
    firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
    firebase.listen_orders(
        on_change=print_orders,
        on_error=log_error,
        retry_delay_seconds=5.0,
    )

