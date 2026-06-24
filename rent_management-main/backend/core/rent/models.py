import uuid

from django.db import models

# =====================================================

# USERS

# =====================================================

class Users(models.Model):
    ROLE_CHOICES = (
        ("owner", "Owner"),
        ("manager", "Manager"),
        ("tenant", "Tenant"),
    )

    STATUS_CHOICES = (
        ("active", "Active"),
        ("inactive", "Inactive"),
        ("blocked", "Blocked"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    name = models.CharField(
        max_length=200
    )

    phone = models.CharField(
        max_length=15,
        unique=True
    )

    email = models.EmailField(
        unique=True,
        null=True,
        blank=True
    )

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="active"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    class Meta:
        db_table = "users"

    def __str__(self):
        return self.name

# =====================================================

# OTP

# =====================================================

class OTP(models.Model):
    id = models.UUIDField(
    primary_key=True,
    default=uuid.uuid4,
    editable=False
    )

    email = models.EmailField()

    otp = models.CharField(
        max_length=6
    )

    attempts = models.IntegerField(
        default=0
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    expires_at = models.DateTimeField()

    class Meta:
        db_table = "otp"


# =====================================================

# BUILDINGS

# =====================================================

class Building(models.Model):


    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    name = models.CharField(
        max_length=200
    )

    address = models.TextField()

    city = models.CharField(
        max_length=100
    )

    state = models.CharField(
        max_length=100
    )

    pincode = models.CharField(
        max_length=10
    )

    total_floors = models.PositiveIntegerField(
        default=1
    )

    description = models.TextField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "buildings"

    def __str__(self):
        return self.name

# =====================================================

# FLOORS

# =====================================================

class Floor(models.Model):
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        related_name="floors"
    )

    floor_number = models.IntegerField()

    floor_name = models.CharField(
        max_length=100,
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "floors"
        unique_together = ("building", "floor_number")

    def __str__(self):
        return f"{self.building.name} - Floor {self.floor_number}"

# =====================================================

# FLATS

# =====================================================

class Flat(models.Model):

    STATUS_CHOICES = (
        ("vacant", "Vacant"),
        ("occupied", "Occupied"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE
    )

    floor = models.ForeignKey(
        Floor,
        on_delete=models.CASCADE
    )

    flat_number = models.CharField(
        max_length=50
    )

    capacity = models.PositiveIntegerField(
        default=1
    )

    occupied_count = models.PositiveIntegerField(
        default=0
    )

    allow_sharing = models.BooleanField(
        default=False
    )

    base_rent = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="vacant"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "flats"

    def __str__(self):
        return self.flat_number


# =====================================================

# ROOMS

# =====================================================

class Room(models.Model):
    STATUS_CHOICES = (
        ("vacant", "Vacant"),
        ("occupied", "Occupied"),
        ("maintenance", "Maintenance"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE
    )

    floor = models.ForeignKey(
        Floor,
        on_delete=models.CASCADE
    )

    flat = models.ForeignKey(
        Flat,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    room_number = models.CharField(
        max_length=50
    )

    room_type = models.CharField(
        max_length=50
    )

    capacity = models.PositiveIntegerField(
        default=1
    )

    occupied_count = models.PositiveIntegerField(
        default=0
    )

    allow_sharing = models.BooleanField(
        default=False
    )

    base_rent = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    notice_period_days = models.PositiveIntegerField(
        default=30
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="vacant"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "rooms"

    def __str__(self):
        return self.room_number




# =====================================================
# RENTAL UNITS
# =====================================================

class RentalUnit(models.Model):

    UNIT_TYPES = (
        ("building", "Building"),
        ("floor", "Floor"),
        ("flat", "Flat"),
        ("room", "Room"),
    )

    STATUS_CHOICES = (
        ("vacant", "Vacant"),
        ("occupied", "Occupied"),
        ("partial", "Partially Occupied"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    unit_type = models.CharField(
        max_length=20,
        choices=UNIT_TYPES
    )

    building = models.ForeignKey(
        Building,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    floor = models.ForeignKey(
        Floor,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    flat = models.ForeignKey(
        Flat,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )

    room = models.ForeignKey(
        Room,
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )


    rent = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    capacity = models.PositiveIntegerField(
        default=1
    )

    occupied_count = models.PositiveIntegerField(
        default=0
    )

    allow_sharing = models.BooleanField(
        default=False
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="vacant"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "rental_units"

    def __str__(self):
        return f"{self.unit_type} - {self.id}"


# =====================================================
# TENANT ASSIGNMENTS
# =====================================================

class TenantAssignment(models.Model):

    STATUS_CHOICES = (
        ("active", "Active"),
        ("pending", "Pending"),
        ("vacated", "Vacated"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    tenant = models.ForeignKey(
        Users,
        on_delete=models.CASCADE,
        related_name="tenant_assignments"
    )

    rental_unit = models.ForeignKey(
        RentalUnit,
        on_delete=models.CASCADE,
        related_name="assignments"
    )

    # Important:
    # True = tenant occupies entire room/flat/building
    # False = shared occupancy allowed
    exclusive_occupancy = models.BooleanField(
        default=False
    )

    security_deposit = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0
    )

    discount_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0
    )

    final_rent = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    rent_start_date = models.DateField()

    rent_end_date = models.DateField(
        null=True,
        blank=True
    )

    assigned_by = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True,
        related_name="assigned_tenants"
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="active"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "tenant_assignments"

    def __str__(self):
        return f"{self.tenant.name}"


# =====================================================
# ELECTRICITY READINGS
# =====================================================

class ElectricityReading(models.Model):

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    room = models.ForeignKey(
        Room,
        on_delete=models.CASCADE
    )

    reading_month = models.DateField()

    previous_reading = models.IntegerField()

    current_reading = models.IntegerField()

    units_consumed = models.IntegerField()

    unit_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    entered_by = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "electricity_readings"

    def __str__(self):
        return str(self.reading_month)


# =====================================================
# BILLS
# =====================================================

class Bill(models.Model):

    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("paid", "Paid"),
        ("partial", "Partial"),
        ("overdue", "Overdue"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    assignment = models.ForeignKey(
        TenantAssignment,
        on_delete=models.CASCADE
    )

    bill_month = models.DateField()

    rent_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    electricity_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0
    )

    additional_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0
    )

    total_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    due_date = models.DateField()

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "bills"

    def __str__(self):
        return str(self.bill_month)


# =====================================================
# ADDITIONAL CHARGES
# =====================================================

class AdditionalCharge(models.Model):

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    bill = models.ForeignKey(
        Bill,
        on_delete=models.CASCADE,
        related_name="charges"
    )

    charge_name = models.CharField(
        max_length=200
    )

    charge_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    notes = models.TextField(
        blank=True,
        null=True
    )

    class Meta:
        db_table = "additional_charges"

    def __str__(self):
        return self.charge_name


# =====================================================
# PAYMENTS
# =====================================================

class Payment(models.Model):

    PAYMENT_MODES = (
        ("cash", "Cash"),
        ("upi", "UPI"),
        ("bank", "Bank"),
        ("card", "Card"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    bill = models.ForeignKey(
        Bill,
        on_delete=models.CASCADE
    )

    amount_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    payment_mode = models.CharField(
        max_length=20,
        choices=PAYMENT_MODES
    )

    utr_number = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    paid_at = models.DateTimeField()

    received_by = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True
    )

    class Meta:
        db_table = "payments"


# =====================================================
# PAYMENT TRANSACTIONS
# =====================================================

class PaymentTransaction(models.Model):

    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("success", "Success"),
        ("failed", "Failed"),
        ("refunded", "Refunded"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    payment = models.ForeignKey(
        Payment,
        on_delete=models.CASCADE,
        related_name="transactions"
    )

    gateway_name = models.CharField(
        max_length=100
    )

    gateway_order_id = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    gateway_payment_id = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )

    gateway_signature = models.TextField(
        blank=True,
        null=True
    )

    transaction_status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2
    )

    currency = models.CharField(
        max_length=10,
        default="INR"
    )

    gateway_response = models.JSONField(
        blank=True,
        null=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "payment_transactions"

# =====================================================
# COMPLAINTS
# =====================================================

class Complaint(models.Model):

    STATUS_CHOICES = (
        ("open", "Open"),
        ("in_progress", "In Progress"),
        ("resolved", "Resolved"),
        ("closed", "Closed"),
    )

    PRIORITY_CHOICES = (
        ("low", "Low"),
        ("medium", "Medium"),
        ("high", "High"),
        ("urgent", "Urgent"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    tenant = models.ForeignKey(
        Users,
        on_delete=models.CASCADE,
        related_name="complaints"
    )

    assignment = models.ForeignKey(
        TenantAssignment,
        on_delete=models.CASCADE
    )

    title = models.CharField(
        max_length=255
    )

    description = models.TextField()

    priority = models.CharField(
        max_length=20,
        choices=PRIORITY_CHOICES,
        default="medium"
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="open"
    )

    assigned_to = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="assigned_complaints"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    resolved_at = models.DateTimeField(
        null=True,
        blank=True
    )

    class Meta:
        db_table = "complaints"

    def __str__(self):
        return self.title


# =====================================================
# MAINTENANCE REQUESTS
# =====================================================

class MaintenanceRequest(models.Model):

    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("assigned", "Assigned"),
        ("in_progress", "In Progress"),
        ("completed", "Completed"),
        ("cancelled", "Cancelled"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    complaint = models.ForeignKey(
        Complaint,
        on_delete=models.CASCADE,
        related_name="maintenance_requests"
    )

    assigned_to = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    notes = models.TextField(
        blank=True,
        null=True
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    completed_at = models.DateTimeField(
        null=True,
        blank=True
    )

    class Meta:
        db_table = "maintenance_requests"


# =====================================================
# DOCUMENTS
# =====================================================

class Document(models.Model):

    DOCUMENT_TYPES = (
        ("aadhaar", "Aadhaar"),
        ("pan", "PAN"),
        ("passport", "Passport"),
        ("license", "Driving License"),
        ("photo", "Photo"),
        ("other", "Other"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    tenant = models.ForeignKey(
        Users,
        on_delete=models.CASCADE
    )

    assignment = models.ForeignKey(
        TenantAssignment,
        on_delete=models.CASCADE
    )

    document_type = models.CharField(
        max_length=50,
        choices=DOCUMENT_TYPES
    )

    document_name = models.CharField(
        max_length=255
    )

    document_url = models.TextField()

    uploaded_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "documents"

    def __str__(self):
        return self.document_name


# =====================================================
# VACATE NOTICES
# =====================================================

class VacateNotice(models.Model):

    STATUS_CHOICES = (
        ("pending", "Pending"),
        ("approved", "Approved"),
        ("rejected", "Rejected"),
        ("completed", "Completed"),
    )

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    tenant = models.ForeignKey(
        Users,
        on_delete=models.CASCADE
    )

    assignment = models.ForeignKey(
        TenantAssignment,
        on_delete=models.CASCADE
    )

    notice_date = models.DateField()

    vacate_date = models.DateField()

    reason = models.TextField(
        blank=True,
        null=True
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="pending"
    )

    approved_by = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="approved_vacate_notices"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "vacate_notices"


# =====================================================
# NOTIFICATIONS
# =====================================================

class Notification(models.Model):

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    user = models.ForeignKey(
        Users,
        on_delete=models.CASCADE
    )

    title = models.CharField(
        max_length=255
    )

    message = models.TextField()

    is_read = models.BooleanField(
        default=False
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "notifications"

    def __str__(self):
        return self.title


# =====================================================
# SETTINGS
# =====================================================

class Setting(models.Model):

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    company_name = models.CharField(
        max_length=255
    )

    company_phone = models.CharField(
        max_length=20
    )

    company_email = models.EmailField()

    company_address = models.TextField(
        blank=True,
        null=True
    )

    default_notice_days = models.PositiveIntegerField(
        default=30
    )

    default_electricity_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0
    )

    updated_at = models.DateTimeField(
        auto_now=True
    )

    class Meta:
        db_table = "settings"

    def __str__(self):
        return self.company_name


# =====================================================
# AUDIT LOGS
# =====================================================

class AuditLog(models.Model):

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    user = models.ForeignKey(
        Users,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    module = models.CharField(
        max_length=100
    )

    action = models.CharField(
        max_length=200
    )

    description = models.TextField()

    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = "audit_logs"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.module} - {self.action}"