from sqlalchemy.orm import (
    declarative_base,
    sessionmaker,
    relationship
)
from sqlalchemy import (
    Float,
    create_engine,
    Column,
    Integer,
    String,
    Date,
    DateTime,
    BigInteger,
    ForeignKey,
    select,
    func
)

from faker import Faker
import random
import time


Base = declarative_base()


class User(Base):

    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    birth_date = Column(Date)
    tel_number = Column(String)
    email = Column(String(50))
    password = Column(String(50))
    created_at = Column(DateTime)
    update_at = Column(DateTime)

    orders = relationship("Order", back_populates="user")


class Order(Base):

    __tablename__ = 'orders'

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    order_date = Column(DateTime)
    order_price = Column(Float)
    created_at = Column(DateTime)
    update_at = Column(DateTime)

    user = relationship("User", back_populates="orders")
    order_products = relationship("Order_product", back_populates="order")


class Restaurant(Base):

    __tablename__ = 'restaurants'

    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    tel_number = Column(String)
    created_at = Column(DateTime)
    update_at = Column(DateTime)

    products = relationship("Product", back_populates="restaurant")


class Product(Base):

    __tablename__ = 'products'

    id = Column(Integer, primary_key=True)
    name = Column(String(50))
    restaurant_id = Column(Integer, ForeignKey("restaurants.id"))
    price = Column(Float)
    created_at = Column(DateTime)
    update_at = Column(DateTime)

    restaurant = relationship("Restaurant", back_populates="products")
    order_products = relationship("Order_product", back_populates="product")


class Order_product(Base):

    __tablename__ = 'order_products'

    id = Column(Integer, primary_key=True)
    order_id = Column(Integer, ForeignKey("orders.id"))
    product_id = Column(Integer, ForeignKey("products.id"))
    created_at = Column(DateTime)
    update_at = Column(DateTime)

    order = relationship("Order", back_populates="order_products")
    product = relationship("Product", back_populates="order_products")


def create_user():
    user = User(
        name=fake.name(),
        birth_date=fake.date_between(start_date="-60y", end_date="-15y"),
        tel_number=fake.phone_number(),
        email=fake.ascii_email(),
        password=fake.password(),
        created_at=fake.date_time_between(start_date="-5y")
    )

    session.add(user)
    session.commit()

    return user


def create_restaurant():
    restaurant = Restaurant(
        name=fake.company(),
        tel_number=fake.phone_number(),
        created_at=fake.date_time_between(start_date="-5y")
    )

    session.add(restaurant)
    session.commit()

    products = random.randint(3, 15)
    for _ in range(products):
        product = create_product(restaurant_id=restaurant.id)
        print("Prod", product.id)

    return restaurant


def create_product(restaurant_id: int) -> Product:
    product = Product(
        name=" ".join(fake.words(nb=2)),
        restaurant_id=restaurant_id,
        price=round(random.uniform(10, 100), 2),
        created_at=fake.date_time_between(start_date="-5y")
    )

    session.add(product)
    session.commit()

    return product


def create_order() -> Order:
    # Setting user that will do the order
    users_count = session.query(func.count(User.id)).scalar()
    user_id = random.randint(1, users_count)

    order_date = fake.date_time_between(start_date="-5y")
    order = Order(
        user_id=user_id,
        order_date=order_date,
        created_at=order_date
    )

    session.add(order)
    session.commit()

    order_price = create_order_products(order_id=order.id)
    order.order_price = order_price
    session.commit()

    return order


def create_order_products(order_id: int):

    # Setting the restaurant
    restaurants_count = session.query(func.count(Restaurant.id)).scalar()
    restaurant_id = random.randint(1, restaurants_count)

    # Getting all products by restorant
    products_and_prices = session.execute(
        select(Product.id, Product.price)
        .where(Product.restaurant_id == restaurant_id)
    ).all()

    # Selecting products for the order
    final_products = random.choices(products_and_prices, k=6)

    # Creating order_products
    order_price = 0
    for product in final_products:
        order_product = Order_product(
            order_id=order_id,
            product_id=product[0],
            created_at=fake.date_time_between(start_date="-5y")
        )

        session.add(order_product)
        session.commit()

        order_price += product[1]

    return order_price


if __name__ == "__main__":

    engine = create_engine(
        "postgresql://ifood_app:JPedro//14@my-postgresql:5432/ifood",
        echo=False
    )

    Base.metadata.create_all(engine)

    Session = sessionmaker(bind=engine)
    session = Session()

    fake = Faker("pt_BR")

    # First population
    create_user()
    create_restaurant()

    # Data generation loop
    while True:

        actions = [
            "create_user",
            "create_restaurant",
            "create_order"
        ]

        action_index = random.randint(0, len(actions)-1)

        if actions[action_index] == "create_user":
            for _ in range(50):
                create_user()

        elif actions[action_index] == "create_restaurant":
            create_restaurant()

        elif actions[action_index] == "create_order":
            for _ in range(100):
                create_order()

        time.sleep(1)
