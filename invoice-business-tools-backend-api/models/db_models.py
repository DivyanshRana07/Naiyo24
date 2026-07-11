# pyrefly: ignore [missing-import]
from sqlalchemy import Column, Integer, String, Date, Numeric, JSON, ForeignKey, DateTime, Boolean, func
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import relationship
from db import Base

class Invoice(Base):
    __tablename__ = "invoices"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    invoice_number = Column(String(50), unique=True, index=True, nullable=False)
    invoice_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=True)
    transaction_type = Column(String(50), nullable=False)
    invoice_type = Column(String(20), default="regular", nullable=False)  # regular or proforma
    notes = Column(String(500), nullable=True)
    subtitle = Column(String(200), nullable=True)
    logo = Column(String, nullable=True)
    settings = Column(JSON, nullable=True)

    business_details = Column(JSON, nullable=False)
    customer_details = Column(JSON, nullable=False)
    tax_breakdown = Column(JSON, nullable=False)

    payment_method = Column(String(50), nullable=True)
    paid_amount = Column(Numeric(12, 2), default=0.00, nullable=False)
    round_off = Column(Numeric(12, 2), default=0.00, nullable=False)
    status = Column(String(50), default="due", nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    user = relationship(
        "User",
        back_populates="invoices"
    )

    items = relationship(
        "InvoiceItem",
        back_populates="invoice",
        cascade="all, delete-orphan"
    )

class InvoiceItem(Base):
    __tablename__ = "invoice_items"

    id = Column(Integer, primary_key=True, index=True)
    invoice_id = Column(Integer, ForeignKey("invoices.id"), nullable=False)
    
    name = Column(String(150), nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
    price = Column(Numeric(12, 2), nullable=False)
    
    gst_rate = Column(Numeric(5, 2), nullable=False)
    taxable_amount = Column(Numeric(12, 2), nullable=False)
    
    cgst_rate = Column(Numeric(5, 2), nullable=False)
    cgst_amount = Column(Numeric(12, 2), nullable=False)
    
    sgst_rate = Column(Numeric(5, 2), nullable=False)
    sgst_amount = Column(Numeric(12, 2), nullable=False)
    
    igst_rate = Column(Numeric(5, 2), nullable=False)
    igst_amount = Column(Numeric(12, 2), nullable=False)
    
    line_total = Column(Numeric(12, 2), nullable=False)

    invoice = relationship("Invoice", back_populates="items")

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    full_name = Column(String(150), nullable=True)
    hashed_password = Column(String(255), nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    invoices = relationship(
        "Invoice",
        back_populates="user"
    )


    quotations = relationship(
        "Quotation",
        back_populates="user"
    )

    vendors = relationship(
        "Vendor",
        back_populates="user"
    )

    expenses = relationship(
        "Expense",
        back_populates="user"
    )

    customers = relationship(
        "Customer",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    items = relationship(
        "Item",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    services = relationship(
        "Service",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    activity_logs = relationship(
        "ActivityLog",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    leads = relationship(
        "Lead",
        back_populates="user",
        cascade="all, delete-orphan"
    )


class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    name = Column(String(150), nullable=False)
    email = Column(String(120), nullable=True)
    phone = Column(String(50), nullable=True)
    company = Column(String(150), nullable=True)
    
    # Lead pipeline status: new, contacted, qualified, converted, lost
    status = Column(String(50), default="new", nullable=False, index=True)
    
    notes = Column(String(1000), nullable=True)
    source = Column(String(100), nullable=True)  # website, referral, cold_call, etc.
    
    converted_to_customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="leads")
    converted_customer = relationship("Customer", foreign_keys=[converted_to_customer_id])


class Quotation(Base):
    __tablename__ = "quotations"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False
    )

    # Customer Details
    customer_id = Column(String(50), nullable=True)
    customer_name = Column(String(150), nullable=False)
    customer_mobile = Column(String(20), nullable=True)
    customer_address = Column(String(300), nullable=True)
    customer_gst = Column(String(50), nullable=True)

    # Quotation Details
    quotation_date = Column(Date, nullable=True)
    valid_until = Column(Date, nullable=True)
    payment_terms = Column(String(150), nullable=True)
    currency = Column(String(20), default="INR")
    notes = Column(String(500), nullable=True)
    
    subtitle = Column(String(200), nullable=True)
    logo = Column(String, nullable=True)
    settings = Column(JSON, nullable=True)

    total = Column(Numeric(12, 2), nullable=False)

    status = Column(
        String(50),
        default="Draft"
    )

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now()
    )

    user = relationship(
        "User",
        back_populates="quotations"
    )

    items = relationship(
        "QuotationItem",
        back_populates="quotation",
        cascade="all, delete-orphan"
    )
class QuotationItem(Base):
    __tablename__ = "quotation_items"

    id = Column(Integer, primary_key=True, index=True)
    quotation_id = Column(Integer, ForeignKey("quotations.id"), nullable=False)
    
    name = Column(String(150), nullable=False)
    price = Column(Numeric(12, 2), nullable=False)
    quantity = Column(Integer, nullable=False)
    discount_percent = Column(Numeric(5, 2), default=0.00, nullable=False)
    gst_percent = Column(Numeric(5, 2), default=0.00, nullable=False)
    
    quotation = relationship("Quotation", back_populates="items")

class Vendor(Base):
    __tablename__ = "vendors"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    name = Column(String(150), nullable=False)
    email = Column(String(120), nullable=True)
    phone = Column(String(50), nullable=True)
    address = Column(String(255), nullable=True)
    gstin = Column(String(15), nullable=True)
    contact_person = Column(String(150), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="vendors")
    expenses = relationship("Expense", back_populates="vendor")

class Expense(Base):
    __tablename__ = "expenses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id"), nullable=False)
    expense_number = Column(String(50), unique=True, index=True, nullable=False)
    expense_date = Column(Date, nullable=False)
    expected_delivery_date = Column(Date, nullable=True)
    status = Column(String(50), default="Draft")
    notes = Column(String(500), nullable=True)
    title = Column(String(150), nullable=True)
    description = Column(String(500), nullable=True)
    total_amount = Column(Numeric(12, 2), default=0.00, nullable=True)
    gst_amount = Column(Numeric(12, 2), default=0.00, nullable=True)
    receipt_image = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="expenses")
    vendor = relationship("Vendor", back_populates="expenses")
    items = relationship("ExpenseItem", back_populates="expense", cascade="all, delete-orphan")

class ExpenseItem(Base):
    __tablename__ = "expense_items"

    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey("expenses.id"), nullable=False)
    name = Column(String(150), nullable=False)
    quantity = Column(Numeric(10, 2), nullable=False)
    price = Column(Numeric(12, 2), nullable=False)
    gst_rate = Column(Numeric(5, 2), default=0.00)
    line_total = Column(Numeric(12, 2), nullable=False)

    expense = relationship("Expense", back_populates="items")

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    code = Column(String(50), nullable=False)
    name = Column(String(150), nullable=False)
    mobile = Column(String(50), nullable=False)
    email = Column(String(120), nullable=True)
    address = Column(String(500), nullable=True)
    gst_number = Column(String(50), nullable=True)
    opening_balance = Column(Numeric(12, 2), default=0.00, nullable=False)
    credit_limit = Column(Numeric(12, 2), default=0.00, nullable=False)
    status = Column(String(50), default="active", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="customers")

class Item(Base):
    __tablename__ = "items"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    code = Column(String(50), nullable=False)
    name = Column(String(150), nullable=False)
    category = Column(String(100), nullable=False)
    unit = Column(String(50), nullable=False)
    purchase_price = Column(Numeric(12, 2), nullable=False)
    selling_price = Column(Numeric(12, 2), nullable=False)
    stock_qty = Column(Integer, default=0, nullable=False)
    gst_percent = Column(Numeric(5, 2), nullable=False)
    status = Column(String(50), default="active", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="items")

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    code = Column(String(50), nullable=False)
    name = Column(String(150), nullable=False)
    category = Column(String(100), nullable=False)
    selling_price = Column(Numeric(12, 2), nullable=False)
    gst_percent = Column(Numeric(5, 2), nullable=False)
    status = Column(String(50), default="active", nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="services")


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    # Action performed: "Created", "Updated", "Deleted", "Generated"
    action = Column(String(50), nullable=False)

    # Entity type: "Invoice", "Customer", "Vendor", "Expense", etc.
    entity_type = Column(String(50), nullable=False)

    # Entity identifier — stored as string to cover both int IDs and invoice numbers
    entity_id = Column(String(50), nullable=True)

    # Human-readable title: "Invoice Created", "Customer Deleted", etc.
    title = Column(String(200), nullable=False)

    # Full description sentence for the activity feed
    description = Column(String(500), nullable=True)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True
    )

    user = relationship("User", back_populates="activity_logs")

