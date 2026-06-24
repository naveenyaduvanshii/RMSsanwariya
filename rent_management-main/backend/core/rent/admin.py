# admin.py

from django.contrib import admin

from .models import (
    Users,
    OTP,
    Building,
    Floor,
    Flat,
    Room,
    RentalUnit,
    TenantAssignment,
    ElectricityReading,
    Bill,
    AdditionalCharge,
    Payment,
    PaymentTransaction,
    Complaint,
    MaintenanceRequest,
    Document,
    VacateNotice,
    Notification,
    Setting,
    AuditLog,
)

# =====================================================
# USER
# =====================================================

@admin.register(Users)
class UserAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "phone",
        "email",
        "role",
        "status",
        "created_at",
    )
    list_filter = ("role", "status")
    search_fields = ("name", "phone", "email")


# =====================================================
# OTP
# =====================================================

@admin.register(OTP)
class OTPAdmin(admin.ModelAdmin):
    list_display = (
        "email",
        "otp",
        "attempts",
        "expires_at",
    )
    search_fields = ("email",)


# =====================================================
# BUILDING
# =====================================================

@admin.register(Building)
class BuildingAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "city",
        "state",
        "total_floors",
    )
    search_fields = (
        "name",
        "city",
        "state",
    )


# =====================================================
# FLOOR
# =====================================================

@admin.register(Floor)
class FloorAdmin(admin.ModelAdmin):
    list_display = (
        "building",
        "floor_number",
        "floor_name",
    )
    list_filter = ("building",)


# =====================================================
# FLAT
# =====================================================

@admin.register(Flat)
class FlatAdmin(admin.ModelAdmin):
    list_display = (
        "flat_number",
        "building",
        "floor",
        "capacity",
        "occupied_count",
        "status",
    )
    list_filter = ("status", "building")


# =====================================================
# ROOM
# =====================================================

@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = (
        "room_number",
        "building",
        "floor",
        "room_type",
        "capacity",
        "occupied_count",
        "status",
    )
    list_filter = ("status", "building")



# =====================================================
# RENTAL UNIT
# =====================================================

@admin.register(RentalUnit)
class RentalUnitAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "unit_type",
        "rent",
        "capacity",
        "occupied_count",
        "status",
    )
    list_filter = (
        "unit_type",
        "status",
    )


# =====================================================
# TENANT ASSIGNMENT
# =====================================================

@admin.register(TenantAssignment)
class TenantAssignmentAdmin(admin.ModelAdmin):
    list_display = (
        "tenant",
        "rental_unit",
        "final_rent",
        "status",
        "rent_start_date",
    )
    list_filter = ("status",)
    search_fields = ("tenant__name",)


# =====================================================
# ELECTRICITY
# =====================================================

@admin.register(ElectricityReading)
class ElectricityReadingAdmin(admin.ModelAdmin):
    list_display = (
        "room",
        "reading_month",
        "units_consumed",
        "amount",
    )


# =====================================================
# BILL
# =====================================================

@admin.register(Bill)
class BillAdmin(admin.ModelAdmin):
    list_display = (
        "assignment",
        "bill_month",
        "total_amount",
        "status",
        "due_date",
    )
    list_filter = ("status",)


# =====================================================
# ADDITIONAL CHARGE
# =====================================================

@admin.register(AdditionalCharge)
class AdditionalChargeAdmin(admin.ModelAdmin):
    list_display = (
        "charge_name",
        "bill",
        "charge_amount",
    )


# =====================================================
# PAYMENT
# =====================================================

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        "bill",
        "amount_paid",
        "payment_mode",
        "paid_at",
    )
    list_filter = ("payment_mode",)


# =====================================================
# PAYMENT TRANSACTION
# =====================================================

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = (
        "payment",
        "gateway_name",
        "amount",
        "transaction_status",
    )
    list_filter = (
        "transaction_status",
        "gateway_name",
    )


# =====================================================
# COMPLAINT
# =====================================================

@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "tenant",
        "priority",
        "status",
        "created_at",
    )
    list_filter = (
        "priority",
        "status",
    )


# =====================================================
# MAINTENANCE
# =====================================================

@admin.register(MaintenanceRequest)
class MaintenanceRequestAdmin(admin.ModelAdmin):
    list_display = (
        "complaint",
        "assigned_to",
        "status",
        "created_at",
    )
    list_filter = ("status",)


# =====================================================
# DOCUMENT
# =====================================================

@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = (
        "document_name",
        "document_type",
        "tenant",
        "uploaded_at",
    )
    list_filter = ("document_type",)


# =====================================================
# VACATE NOTICE
# =====================================================

@admin.register(VacateNotice)
class VacateNoticeAdmin(admin.ModelAdmin):
    list_display = (
        "tenant",
        "vacate_date",
        "status",
    )
    list_filter = ("status",)


# =====================================================
# NOTIFICATION
# =====================================================

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "user",
        "is_read",
        "created_at",
    )
    list_filter = ("is_read",)


# =====================================================
# SETTINGS
# =====================================================

@admin.register(Setting)
class SettingAdmin(admin.ModelAdmin):
    list_display = (
        "company_name",
        "company_phone",
        "company_email",
        "updated_at",
    )


# =====================================================
# AUDIT LOG
# =====================================================

@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = (
        "module",
        "action",
        "user",
        "ip_address",
        "created_at",
    )
    list_filter = ("module",)
    search_fields = (
        "module",
        "action",
    )