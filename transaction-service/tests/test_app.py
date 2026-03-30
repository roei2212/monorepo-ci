from app import hello_transaction

def test_hello():
    assert hello_transaction() == "Hello from transaction-service"
