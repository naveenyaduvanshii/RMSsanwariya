import json
import random
from datetime import timedelta,date
import uuid
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone   # ✅ FIX
from .models import Users
from django.db import transaction
from django.core.exceptions import ValidationError
from django.db.models import Q
from django.http import JsonResponse
from django.db.models import Sum
from .models import (
    OTP,
AuditLog,
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

@csrf_exempt
def login_user(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "error": "Invalid request method"}, status=405)

    try:
        data = json.loads(request.body)
        identifier = data.get("email")

        if not identifier:
            return JsonResponse({"success": False, "error": "Email or Phone required"}, status=400)

        # 1. Fetch User
        try:
            user = Users.objects.get(Q(email=identifier) | Q(phone=identifier))
        except Users.DoesNotExist:
            return JsonResponse({"success": False, "error": "User not found"}, status=404)

        # 2. Status Check
        if user.status in ["blocked", "inactive"]:
            return JsonResponse({"success": False, "error": f"Account {user.status}"}, status=403)

        # 3. Create Audit Log (Ensure 'user' matches the field name in your AuditLog model)
        AuditLog.objects.create(
            user=user,
            module="Authentication",
            action="Login",
            description=f"{user.name} logged in"
        )

        return JsonResponse({
            "success": True,
            "user": {
                "id": str(user.id),
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "role": user.role,
                "status": user.status,
            }
        }, status=200)

    except Exception as e:
        # Check your terminal for the specific error details when this hits
        return JsonResponse({"success": False, "error": str(e)}, status=500)
@csrf_exempt
def dashboard(request):
    try:
        role = request.GET.get("role")
        user_id = request.GET.get("user_id")
        print(user_id)  # Will print: 4b0e693c-62d7-45b3-b6a7-cce629dbe5ba

        # =====================================================
        # VALIDATION (CORRECTED UUID MATCHES)
        # =====================================================

        if not role:
            return JsonResponse({"success": False, "error": "role is required"}, status=400)

        role = role.lower() # Normalize case variants
        if role not in ["owner", "manager", "tenant"]:
            return JsonResponse({"success": False, "error": "invalid role"}, status=400)

        # Tenant checks must clear UUID string pattern validation checks
        if role == "tenant":
            if not user_id:
                return JsonResponse({"success": False, "error": "user_id is required for tenant"}, status=400)

            try:
                # ✅ Validate by casting string to a real UUID object instead of an integer
                validated_uuid = uuid.UUID(str(user_id))
                user_id = validated_uuid  # Assign validated UUID instance back to user_id reference
            except ValueError:
                return JsonResponse({"success": False, "error": "user_id must be a valid UUID string format"}, status=400)

        # =====================================================
        # OWNER / MANAGER DASHBOARD
        # =====================================================

        if role in ["owner", "manager"]:

            total_buildings = Building.objects.count()
            total_floors = Floor.objects.count()
            total_flats = Flat.objects.count()
            total_rooms = Room.objects.count()

            total_tenants = Users.objects.filter(role="tenant").count()

            occupied_units = RentalUnit.objects.filter(
                status__in=["occupied", "partial"]
            ).count()

            vacant_units = RentalUnit.objects.filter(
                status="vacant"
            ).count()

            pending_bills = Bill.objects.filter(status="pending").count()

            # =================================================
            # CURRENT MONTH REVENUE
            # =================================================

            current_month = date.today().month
            current_year = date.today().year

            monthly_revenue = Payment.objects.filter(
                paid_at__month=current_month,
                paid_at__year=current_year
            ).aggregate(
                total=Sum("amount_paid")
            )["total"] or 0

            # =================================================
            # RECENT PAYMENTS
            # =================================================

            recent_payments = Payment.objects.select_related(
                "bill__assignment__tenant"
            ).order_by("-paid_at")[:5]

            payments_data = []

            for payment in recent_payments:
                payments_data.append({
                    "payment_id": str(payment.id),
                    "tenant_name": payment.bill.assignment.tenant.name if payment.bill and payment.bill.assignment else "",
                    "amount_paid": str(payment.amount_paid),
                    "payment_mode": payment.payment_mode,
                    "paid_at": payment.paid_at.strftime("%d-%m-%Y %H:%M") if payment.paid_at else "",
                })

            # =================================================
            # RECENT COMPLAINTS
            # =================================================

            recent_complaints = Complaint.objects.select_related(
                "tenant"
            ).order_by("-created_at")[:5]

            complaints_data = []

            for complaint in recent_complaints:
                complaints_data.append({
                    "id": str(complaint.id),
                    "tenant_name": complaint.tenant.name if complaint.tenant else "",
                    "title": complaint.title,
                    "priority": complaint.priority,
                    "status": complaint.status,
                })

            # =================================================
            # RECENT VACATE REQUESTS
            # =================================================

            recent_vacates = VacateNotice.objects.select_related(
                "tenant"
            ).order_by("-created_at")[:5]

            vacates_data = []

            for notice in recent_vacates:
                vacates_data.append({
                    "id": str(notice.id),
                    "tenant_name": notice.tenant.name if notice.tenant else "",
                    "vacate_date": str(notice.vacate_date),
                    "status": notice.status,
                })

            return JsonResponse({
                "success": True,
                "dashboard": {
                    "total_buildings": total_buildings,
                    "total_floors": total_floors,
                    "total_flats": total_flats,
                    "total_rooms": total_rooms,
                    "total_tenants": total_tenants,
                    "occupied_units": occupied_units,
                    "vacant_units": vacant_units,
                    "pending_bills": pending_bills,
                    "monthly_revenue": str(monthly_revenue),
                    "recent_payments": payments_data,
                    "recent_complaints": complaints_data,
                    "recent_vacate_requests": vacates_data,
                }
            })

        # =====================================================
        # TENANT DASHBOARD
        # =====================================================

        assignment = TenantAssignment.objects.filter(
            tenant_id=user_id,
            status="active"
        ).select_related("rental_unit").first()

        pending_bills = Bill.objects.filter(
            assignment=assignment,
            status="pending"
        ).count() if assignment else 0

        complaints_count = Complaint.objects.filter(
            tenant_id=user_id
        ).count() if user_id else 0

        recent_payments = Payment.objects.filter(
            bill__assignment__tenant_id=user_id
        ).order_by("-paid_at")[:5] if user_id else []

        payments_data = []

        for payment in recent_payments:
            payments_data.append({
                "payment_id": str(payment.id),
                "amount_paid": str(payment.amount_paid),
                "payment_mode": payment.payment_mode,
                "paid_at": payment.paid_at.strftime("%d-%m-%Y %H:%M") if payment.paid_at else "",
            })

        recent_complaints = Complaint.objects.filter(
            tenant_id=user_id
        ).order_by("-created_at")[:5] if user_id else []

        complaints_data = []

        for complaint in recent_complaints:
            complaints_data.append({
                "title": complaint.title,
                "priority": complaint.priority,
                "status": complaint.status,
            })

        return JsonResponse({
            "success": True,
            "dashboard": {
                "unit_type": assignment.rental_unit.unit_type if assignment and assignment.rental_unit else "",
                "rent": str(assignment.final_rent) if assignment else "0",
                "pending_bills": pending_bills,
                "complaints": complaints_count,
                "recent_payments": payments_data,
                "recent_complaints": complaints_data,
            }
        })

    except Exception as e:
        return JsonResponse({
            "success": False,
            "error": str(e)
        }, status=500)
# =====================================================
# BUILDINGS LIST + CREATE
# =====================================================
@csrf_exempt
def buildings_list(request):

    # GET
    if request.method == "GET":
        buildings = Building.objects.all()

        data = []
        for b in buildings:
            data.append({
                "id": str(b.id),
                "name": b.name,
                "address": b.address,
                "city": b.city,
                "state": b.state,
                "pincode": b.pincode,
                "total_floors": b.total_floors,
            })

        return JsonResponse({
            "success": True,
            "buildings": data
        })

    # CREATE BUILDING + AUTO FLOORS
    if request.method == "POST":

        try:
            data = json.loads(request.body)

            building = Building.objects.create(
                name=data.get("name"),
                address=data.get("address"),
                city=data.get("city", ""),
                state=data.get("state", ""),
                pincode=data.get("pincode", ""),
                total_floors=data.get("total_floors", 1),
            )

            # ✅ AUTO CREATE FLOORS
            for i in range(1, building.total_floors + 1):
                Floor.objects.create(
                    building=building,
                    floor_name=f"Floor {i}",
                    floor_number=i
                )

            return JsonResponse({
                "success": True,
                "message": "Building & Floors created",
                "id": str(building.id)
            })

        except Exception as e:
            return JsonResponse({
                "success": False,
                "error": str(e)
            }, status=400)

# =====================================================
# BUILDING DETAIL (UPDATE + DELETE)
# =====================================================
@csrf_exempt
def building_detail(request, id):

    try:
        building = Building.objects.get(id=id)

        # =========================
        # UPDATE BUILDING (AUTO SYNC FLOORS)
        # =========================
        if request.method == "PUT":

            data = json.loads(request.body)

            building.name = data.get("name", building.name)
            building.address = data.get("address", building.address)
            building.city = data.get("city", building.city)
            building.state = data.get("state", building.state)
            building.pincode = data.get("pincode", building.pincode)

            try:
                new_total_floors = int(
                    data.get(
                        "total_floors",
                        building.total_floors
                    )
                )
            except:
                new_total_floors = building.total_floors

            building.total_floors = new_total_floors
            building.save()

            # Existing floor numbers
            existing_numbers = set(
                Floor.objects.filter(
                    building=building
                ).values_list(
                    "floor_number",
                    flat=True
                )
            )

            # Create missing floors
            for i in range(1, new_total_floors + 1):

                if i not in existing_numbers:
                    Floor.objects.create(
                        building=building,
                        floor_name=str(i),
                        floor_number=i
                    )

            # Delete extra floors
            Floor.objects.filter(
                building=building,
                floor_number__gt=new_total_floors
            ).delete()

            return JsonResponse({
                "success": True,
                "message": "Building updated + floors synced"
            })
        # =========================
        # DELETE BUILDING
        # =========================
        if request.method == "DELETE":

            building.delete()

            return JsonResponse({
                "success": True,
                "message": "Building deleted successfully"
            })

        return JsonResponse({
            "success": False,
            "error": "Method not allowed"
        }, status=405)

    except Building.DoesNotExist:
        return JsonResponse({
            "success": False,
            "error": "Building not found"
        }, status=404)

    except Exception as e:
        return JsonResponse({
            "success": False,
            "error": str(e)
        }, status=500)


#########################################################
# BUILDINGS DROPDOWN
#########################################################

@csrf_exempt
def buildings_dropdown(request):

    if request.method == "GET":

        buildings = Building.objects.all().order_by("name")

        data = []

        for building in buildings:
            data.append({
                "id": str(building.id),
                "name": building.name,
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# FLOORS BY BUILDING
#########################################################

@csrf_exempt
def floors_by_building(request, building_id):

    if request.method == "GET":

        floors = Floor.objects.filter(
            building_id=building_id
        ).order_by("floor_number")

        data = []

        for floor in floors:

            data.append({
                "id": str(floor.id),
                "floor_number": floor.floor_number,
                "floor_name": floor.floor_name,
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# GET FLATS
#########################################################

@csrf_exempt
def flats_list(request):

    if request.method == "GET":

        flats = Flat.objects.select_related(
            "building",
            "floor"
        ).order_by("-created_at")

        data = []

        for flat in flats:

            data.append({
                "id": str(flat.id),
                "building_id": str(flat.building.id),
                "building_name": flat.building.name,
                "floor_id": str(flat.floor.id),
                "floor_number": flat.floor.floor_number,
                "flat_number": flat.flat_number,
                "capacity": flat.capacity,
                "occupied_count": flat.occupied_count,
                "allow_sharing": flat.allow_sharing,
                "base_rent": float(flat.base_rent),
                "status": flat.status,
                "created_at": flat.created_at.strftime("%d-%m-%Y"),
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# GET SINGLE FLAT
#########################################################

@csrf_exempt
def flat_detail(request, flat_id):

    if request.method == "GET":

        try:

            flat = Flat.objects.select_related(
                "building",
                "floor"
            ).get(id=flat_id)

            return JsonResponse({
                "success": True,
                "data": {
                    "id": str(flat.id),
                    "building_id": str(flat.building.id),
                    "floor_id": str(flat.floor.id),
                    "flat_number": flat.flat_number,
                    "capacity": flat.capacity,
                    "occupied_count": flat.occupied_count,
                    "allow_sharing": flat.allow_sharing,
                    "base_rent": float(flat.base_rent),
                    "status": flat.status,
                }
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# CREATE FLAT
#########################################################

@csrf_exempt
def create_flat(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            building = Building.objects.get(
                id=body.get("building_id")
            )

            floor = Floor.objects.get(
                id=body.get("floor_id")
            )

            flat = Flat.objects.create(
                building=building,
                floor=floor,
                flat_number=body.get("flat_number"),
                capacity=body.get("capacity"),
                occupied_count=0,
                allow_sharing=body.get(
                    "allow_sharing",
                    False
                ),
                base_rent=body.get("base_rent"),
                status="vacant"
            )

            return JsonResponse({
                "success": True,
                "message": "Flat created successfully",
                "flat_id": str(flat.id)
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# UPDATE FLAT
#########################################################

@csrf_exempt
def update_flat(request, flat_id):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            flat = Flat.objects.get(id=flat_id)

            if body.get("building_id"):
                flat.building = Building.objects.get(
                    id=body.get("building_id")
                )

            if body.get("floor_id"):
                flat.floor = Floor.objects.get(
                    id=body.get("floor_id")
                )

            flat.flat_number = body.get(
                "flat_number",
                flat.flat_number
            )

            flat.capacity = body.get(
                "capacity",
                flat.capacity
            )

            flat.allow_sharing = body.get(
                "allow_sharing",
                flat.allow_sharing
            )

            flat.base_rent = body.get(
                "base_rent",
                flat.base_rent
            )

            flat.status = body.get(
                "status",
                flat.status
            )

            flat.save()

            return JsonResponse({
                "success": True,
                "message": "Flat updated successfully"
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# DELETE FLAT
#########################################################

@csrf_exempt
def delete_flat(request, flat_id):

    if request.method == "DELETE":

        try:

            flat = Flat.objects.get(id=flat_id)

            flat.delete()

            return JsonResponse({
                "success": True,
                "message": "Flat deleted successfully"
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# FLATS BY FLOOR
#########################################################

@csrf_exempt
def flats_by_floor(request, floor_id):

    if request.method == "GET":

        flats = Flat.objects.filter(
            floor_id=floor_id
        ).order_by("flat_number")

        data = []

        for flat in flats:

            data.append({
                "id": str(flat.id),
                "flat_number": flat.flat_number,
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })

import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from .models import Room, Building, Floor, Flat


# =====================================================
# ROOMS LIST
# =====================================================

@csrf_exempt
def rooms_list(request):

    if request.method == "GET":

        rooms = Room.objects.select_related(
            "building",
            "floor",
            "flat"
        ).order_by("-created_at")

        data = []

        for room in rooms:
            data.append({
                "id": str(room.id),
                "building_id": str(room.building.id),
                "building_name": room.building.name if room.building else None,

                "floor_id": str(room.floor.id),
                "floor_number": room.floor.floor_number if room.floor else None,

                "flat_id": str(room.flat.id) if room.flat else None,
                "flat_number": room.flat.flat_number if room.flat else None,

                "room_number": room.room_number,
                "room_type": room.room_type,
                "capacity": room.capacity,
                "occupied_count": room.occupied_count,
                "allow_sharing": room.allow_sharing,
                "base_rent": float(room.base_rent),
                "status": room.status,
                "created_at": room.created_at.strftime("%d-%m-%Y"),
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


# =====================================================
# CREATE ROOM
# =====================================================

@csrf_exempt
def create_room(request):

    if request.method == "POST":

        try:
            body = json.loads(request.body)

            building = Building.objects.get(id=body.get("building_id"))
            floor = Floor.objects.get(id=body.get("floor_id"))

            flat = None
            if body.get("flat_id"):
                flat = Flat.objects.get(id=body.get("flat_id"))

            room = Room.objects.create(
                building=building,
                floor=floor,
                flat=flat,
                room_number=body.get("room_number"),
                room_type=body.get("room_type"),
                capacity=body.get("capacity", 1),
                occupied_count=0,
                allow_sharing=body.get("allow_sharing", False),
                base_rent=body.get("base_rent", 0),
                status="vacant"
            )

            return JsonResponse({
                "success": True,
                "message": "Room created successfully",
                "room_id": str(room.id)
            })

        except Exception as e:
            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


# =====================================================
# UPDATE ROOM
# =====================================================

@csrf_exempt
def update_room(request, room_id):

    if request.method == "PUT":

        try:
            body = json.loads(request.body)

            room = Room.objects.get(id=room_id)

            if body.get("building_id"):
                room.building = Building.objects.get(id=body.get("building_id"))

            if body.get("floor_id"):
                room.floor = Floor.objects.get(id=body.get("floor_id"))

            if "flat_id" in body:
                flat_id = body.get("flat_id")
                if flat_id:
                    room.flat = Flat.objects.get(id=flat_id)
                else:
                    room.flat = None

            room.room_number = body.get("room_number", room.room_number)
            room.room_type = body.get("room_type", room.room_type)
            room.capacity = body.get("capacity", room.capacity)
            room.base_rent = body.get("base_rent", room.base_rent)
            room.allow_sharing = body.get("allow_sharing", room.allow_sharing)
            room.status = body.get("status", room.status)

            room.save()

            return JsonResponse({
                "success": True,
                "message": "Room updated successfully"
            })

        except Exception as e:
            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


# =====================================================
# DELETE ROOM
# =====================================================

@csrf_exempt
def delete_room(request, room_id):

    if request.method == "DELETE":

        try:
            room = Room.objects.get(id=room_id)
            room.delete()

            return JsonResponse({
                "success": True,
                "message": "Room deleted successfully"
            })

        except Exception as e:
            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })
# =====================================================
# ROOMS DROPDOWN
# =====================================================

@csrf_exempt
def rooms_by_flat(request, flat_id):

    if request.method == "GET":

        rooms = Room.objects.filter(
            flat_id=flat_id
        ).order_by("room_number")

        data = []

        for room in rooms:

            data.append({
                "id": str(room.id),
                "room_number": room.room_number,
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })
########################################################
# LIST ASSIGNMENTS
########################################################

@csrf_exempt
def tenant_assignments_list(request):

    if request.method == "GET":

        assignments = TenantAssignment.objects.select_related(
            "tenant",
            "rental_unit",
            "assigned_by"
        ).order_by("-created_at")

        data = []

        for item in assignments:

            rental_unit = item.rental_unit

            building_name = ""
            floor_name = ""
            flat_number = ""
            room_number = ""
            bed_number = ""

            if rental_unit:

                if rental_unit.building:
                    building_name = rental_unit.building.name

                if rental_unit.floor:
                    floor_name = (
                        rental_unit.floor.floor_name
                        or f"Floor {rental_unit.floor.floor_number}"
                    )

                if rental_unit.flat:
                    flat_number = rental_unit.flat.flat_number

                if rental_unit.room:
                    room_number = rental_unit.room.room_number


            data.append({
                "id": str(item.id),

                "tenant_id": str(item.tenant.id),
                "tenant_name": item.tenant.name,
                "tenant_phone": item.tenant.phone,

                "rental_unit_id": str(rental_unit.id),

                "unit_type": rental_unit.unit_type,

                "building_name": building_name,
                "floor_name": floor_name,
                "flat_number": flat_number,
                "room_number": room_number,
                "bed_number": bed_number,

                "security_deposit":
                    float(item.security_deposit),

                "discount_percent":
                    float(item.discount_percent),

                "final_rent":
                    float(item.final_rent),

                "exclusive_occupancy":
                    item.exclusive_occupancy,

                "rent_start_date":
                    item.rent_start_date.strftime(
                        "%Y-%m-%d"
                    ),

                "rent_end_date":
                    item.rent_end_date.strftime(
                        "%Y-%m-%d"
                    )
                    if item.rent_end_date
                    else None,

                "status":
                    item.status,

                "assigned_by":
                    item.assigned_by.name
                    if item.assigned_by
                    else ""
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


########################################################
# CREATE ASSIGNMENT
########################################################

@csrf_exempt
def add_tenant_assignment(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            tenant = Users.objects.get(
                id=body.get("tenant_id")
            )

            rental_unit = RentalUnit.objects.get(
                id=body.get("rental_unit_id")
            )

            assignment = TenantAssignment.objects.create(
                tenant=tenant,
                rental_unit=rental_unit,

                exclusive_occupancy=
                    body.get(
                        "exclusive_occupancy",
                        False
                    ),

                security_deposit=
                    body.get(
                        "security_deposit",
                        0
                    ),

                discount_percent=
                    body.get(
                        "discount_percent",
                        0
                    ),

                final_rent=
                    body.get(
                        "final_rent",
                        rental_unit.rent
                    ),

                rent_start_date=
                    body.get(
                        "rent_start_date"
                    ),

                assigned_by=None,
                status="active"
            )

            rental_unit.occupied_count += 1

            if rental_unit.occupied_count == 0:
                rental_unit.status = "vacant"

            elif rental_unit.occupied_count < rental_unit.capacity:
                rental_unit.status = "partial"

            else:
                rental_unit.status = "occupied"

            rental_unit.save()

            return JsonResponse({
                "success": True,
                "message":
                    "Tenant assigned successfully",
                "id": str(assignment.id)
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


########################################################
# UPDATE ASSIGNMENT
########################################################

@csrf_exempt
def update_tenant_assignment(
    request,
    assignment_id
):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            assignment = (
                TenantAssignment.objects.get(
                    id=assignment_id
                )
            )

            assignment.security_deposit = (
                body.get(
                    "security_deposit",
                    assignment.security_deposit
                )
            )

            assignment.discount_percent = (
                body.get(
                    "discount_percent",
                    assignment.discount_percent
                )
            )

            assignment.final_rent = (
                body.get(
                    "final_rent",
                    assignment.final_rent
                )
            )

            assignment.status = (
                body.get(
                    "status",
                    assignment.status
                )
            )

            assignment.save()

            return JsonResponse({
                "success": True,
                "message":
                    "Assignment updated successfully"
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


########################################################
# VACATE TENANT
########################################################

@csrf_exempt
def vacate_tenant(
    request,
    assignment_id
):

    if request.method == "PUT":

        try:

            assignment = (
                TenantAssignment.objects.get(
                    id=assignment_id
                )
            )

            assignment.status = "vacated"
            assignment.save()

            rental_unit = assignment.rental_unit

            if rental_unit.occupied_count > 0:
                rental_unit.occupied_count -= 1

            if rental_unit.occupied_count == 0:
                rental_unit.status = "vacant"

            elif rental_unit.occupied_count < rental_unit.capacity:
                rental_unit.status = "partial"

            else:
                rental_unit.status = "occupied"

            rental_unit.save()

            return JsonResponse({
                "success": True,
                "message":
                    "Tenant vacated successfully"
            })

        except Exception as e:

            return JsonResponse({
                "success": False,
                "message": str(e)
            })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


########################################################
# TENANTS DROPDOWN
########################################################

@csrf_exempt
def tenants_dropdown(request):

    if request.method == "GET":

        tenants = Users.objects.filter(
            role="tenant",
            status="active"
        ).order_by("name")

        data = []

        for tenant in tenants:

            data.append({
                "id": str(tenant.id),
                "name": tenant.name,
                "phone": tenant.phone
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False
    })


########################################################
# RENTAL UNITS DROPDOWN
########################################################

@csrf_exempt
def rental_units_dropdown(request):

    if request.method == "GET":

        units = RentalUnit.objects.filter(
            status__in=["vacant", "partial"]
        )

        data = []

        for unit in units:

            data.append({
                "id": str(unit.id),
                "unit_type": unit.unit_type,
                "rent": float(unit.rent),
                "status": unit.status
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False
    })

#########################################################
# RENTAL UNITS LIST
#########################################################

@csrf_exempt
def rental_units_list(request):

    if request.method == "GET":

        units = RentalUnit.objects.select_related(
            "building",
            "floor",
            "flat",
            "room"
        ).order_by("-created_at")

        data = []

        for unit in units:

            data.append({

                "id": str(unit.id),

                "unit_type": unit.unit_type,

                "building_id":
                    str(unit.building.id)
                    if unit.building else None,

                "building_name":
                    unit.building.name
                    if unit.building else "",

                "floor_id":
                    str(unit.floor.id)
                    if unit.floor else None,

                "floor_number":
                    unit.floor.floor_number
                    if unit.floor else "",

                "flat_id":
                    str(unit.flat.id)
                    if unit.flat else None,

                "flat_number":
                    unit.flat.flat_number
                    if unit.flat else "",

                "room_id":
                    str(unit.room.id)
                    if unit.room else None,

                "room_number":
                    unit.room.room_number
                    if unit.room else "",

                "bed_id": None,

                "bed_number": "",

                "rent":
                    float(unit.rent),

                "capacity":
                    unit.capacity,

                "occupied_count":
                    unit.occupied_count,

                "allow_sharing":
                    unit.allow_sharing,

                "status":
                    unit.status,

                "created_at":
                    unit.created_at.strftime(
                        "%d-%m-%Y"
                    )
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


#########################################################
# CREATE RENTAL UNIT
#########################################################

@csrf_exempt
def create_rental_unit(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            unit_type = body.get("unit_type")

            building = None
            floor = None
            flat = None
            room = None

            if body.get("building_id"):
                building = Building.objects.get(
                    id=body.get("building_id")
                )

            if body.get("floor_id"):
                floor = Floor.objects.get(
                    id=body.get("floor_id")
                )

            if body.get("flat_id"):
                flat = Flat.objects.get(
                    id=body.get("flat_id")
                )

            if body.get("room_id"):
                room = Room.objects.get(
                    id=body.get("room_id")
                )

            rental_unit = RentalUnit.objects.create(

                unit_type=unit_type,

                building=building,

                floor=floor,

                flat=flat,

                room=room,

                rent=body.get(
                    "rent",
                    0
                ),

                capacity=body.get(
                    "capacity",
                    1
                ),

                occupied_count=0,

                allow_sharing=body.get(
                    "allow_sharing",
                    False
                ),

                status="vacant"
            )

            return JsonResponse({

                "success": True,

                "message":
                    "Rental Unit created successfully",

                "id":
                    str(rental_unit.id)
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)

            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"

    })


#########################################################
# UPDATE RENTAL UNIT
#########################################################

@csrf_exempt
def update_rental_unit(
    request,
    rental_unit_id
):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            unit = RentalUnit.objects.get(
                id=rental_unit_id
            )

            if body.get("building_id"):

                unit.building = (
                    Building.objects.get(
                        id=body.get(
                            "building_id"
                        )
                    )
                )

            if body.get("floor_id"):

                unit.floor = (
                    Floor.objects.get(
                        id=body.get(
                            "floor_id"
                        )
                    )
                )

            if body.get("flat_id"):

                unit.flat = (
                    Flat.objects.get(
                        id=body.get(
                            "flat_id"
                        )
                    )
                )

            if body.get("room_id"):

                unit.room = (
                    Room.objects.get(
                        id=body.get(
                            "room_id"
                        )
                    )
                )


            unit.unit_type = body.get(
                "unit_type",
                unit.unit_type
            )

            unit.rent = body.get(
                "rent",
                unit.rent
            )

            unit.capacity = body.get(
                "capacity",
                unit.capacity
            )

            unit.occupied_count = body.get(
                "occupied_count",
                unit.occupied_count
            )

            unit.allow_sharing = body.get(
                "allow_sharing",
                unit.allow_sharing
            )

            unit.status = body.get(
                "status",
                unit.status
            )

            unit.save()

            return JsonResponse({

                "success": True,

                "message":
                    "Rental Unit updated successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)

            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"

    })


#########################################################
# DELETE RENTAL UNIT
#########################################################

@csrf_exempt
def delete_rental_unit(
    request,
    rental_unit_id
):

    if request.method == "DELETE":

        try:

            unit = RentalUnit.objects.get(
                id=rental_unit_id
            )

            unit.delete()

            return JsonResponse({

                "success": True,

                "message":
                    "Rental Unit deleted successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)

            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"

    })

########################################################
# TENANTS LIST
########################################################

@csrf_exempt
def tenants_list(request):

    if request.method == "GET":

        tenants = Users.objects.filter(
            role="tenant"
        ).order_by("-created_at")

        data = []

        for tenant in tenants:

            active_assignment = (
                TenantAssignment.objects.filter(
                    tenant=tenant,
                    status="active"
                )
                .select_related("rental_unit")
                .first()
            )

            unit_type = ""
            final_rent = 0

            if active_assignment:

                unit_type = (
                    active_assignment.rental_unit.unit_type
                    if active_assignment.rental_unit
                    else ""
                )

                final_rent = (
                    active_assignment.final_rent
                )

            data.append({

                "id": str(tenant.id),

                "name": tenant.name,

                "phone": tenant.phone,

                "email": tenant.email,

                "status": tenant.status,

                "unit_type": unit_type,

                "rent": float(final_rent),

                "created_at":
                    tenant.created_at.strftime(
                        "%d-%m-%Y"
                    ),
            })

        return JsonResponse({

            "success": True,

            "data": data

        })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# TENANT DETAIL
########################################################

@csrf_exempt
def tenant_detail(request, tenant_id):

    if request.method == "GET":

        try:

            tenant = Users.objects.get(
                id=tenant_id,
                role="tenant"
            )

            return JsonResponse({

                "success": True,

                "data": {

                    "id": str(tenant.id),

                    "name": tenant.name,

                    "phone": tenant.phone,

                    "email": tenant.email,

                    "status": tenant.status,

                    "created_at":
                        tenant.created_at.strftime(
                            "%d-%m-%Y"
                        ),
                }
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message": str(e)

            })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# CREATE TENANT
########################################################

@csrf_exempt
def create_tenant(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            tenant = Users.objects.create(

                name=body.get("name"),

                phone=body.get("phone"),

                email=body.get("email"),

                role="tenant",

                status="active"
            )

            return JsonResponse({

                "success": True,

                "message":
                    "Tenant created successfully",

                "tenant_id":
                    str(tenant.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message": str(e)

            })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# UPDATE TENANT
########################################################

@csrf_exempt
def update_tenant(request, tenant_id):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            tenant = Users.objects.get(
                id=tenant_id,
                role="tenant"
            )

            tenant.name = body.get(
                "name",
                tenant.name
            )

            tenant.phone = body.get(
                "phone",
                tenant.phone
            )

            tenant.email = body.get(
                "email",
                tenant.email
            )

            tenant.status = body.get(
                "status",
                tenant.status
            )

            tenant.save()

            return JsonResponse({

                "success": True,

                "message":
                    "Tenant updated successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message": str(e)

            })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# DELETE TENANT
########################################################

@csrf_exempt
def delete_tenant(request, tenant_id):

    if request.method == "DELETE":

        try:

            tenant = Users.objects.get(
                id=tenant_id,
                role="tenant"
            )

            tenant.delete()

            return JsonResponse({

                "success": True,

                "message":
                    "Tenant deleted successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message": str(e)

            })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# TENANT PROFILE
########################################################

@csrf_exempt
def tenant_profile(request, tenant_id):

    if request.method == "GET":

        try:

            tenant = Users.objects.get(
                id=tenant_id
            )

            assignment = (
                TenantAssignment.objects.filter(
                    tenant=tenant,
                    status="active"
                )
                .select_related(
                    "rental_unit"
                )
                .first()
            )

            assignment_data = None

            if assignment:

                assignment_data = {

                    "assignment_id":
                        str(assignment.id),

                    "unit_type":
                        assignment.rental_unit.unit_type,

                    "rent":
                        float(
                            assignment.final_rent
                        ),

                    "security_deposit":
                        float(
                            assignment.security_deposit
                        ),

                    "rent_start_date":
                        assignment.rent_start_date.strftime(
                            "%Y-%m-%d"
                        )
                }

            return JsonResponse({

                "success": True,

                "tenant": {

                    "id": str(tenant.id),

                    "name": tenant.name,

                    "phone": tenant.phone,

                    "email": tenant.email,

                    "status": tenant.status,
                },

                "assignment":
                    assignment_data

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message": str(e)

            })

    return JsonResponse({

        "success": False,

        "message": "Invalid Request"

    })
########################################################
# ELECTRICITY READINGS LIST
########################################################
@csrf_exempt
def electricity_readings_list(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        readings = ElectricityReading.objects.select_related(
            "room",
            "room__building",
            "room__floor",
            "entered_by"
        ).order_by("-reading_month")

        data = []
        for item in readings:
            # Safe formatting for Date objects across DB variants
            reading_month_str = (
                item.reading_month.strftime("%Y-%m-%d")
                if isinstance(item.reading_month, (date, date))
                else str(item.reading_month or "")
            )
            created_at_str = (
                item.created_at.strftime("%d-%m-%Y")
                if isinstance(item.created_at, (date, date))
                else str(item.created_at or "")
            )

            data.append({
                "id": str(item.id),
                "building_id": str(item.room.building.id) if (item.room and item.room.building) else None,
                "building_name": item.room.building.name if (item.room and item.room.building) else "",
                "floor_id": str(item.room.floor.id) if (item.room and item.room.floor) else None,
                "floor_number": item.room.floor.floor_number if (item.room and item.room.floor) else "",
                "room_id": str(item.room.id) if item.room else None,
                "room_number": item.room.room_number if item.room else "",
                "reading_month": reading_month_str,
                "previous_reading": int(item.previous_reading or 0),
                "current_reading": int(item.current_reading or 0),
                "units_consumed": int(item.units_consumed or 0),
                "unit_rate": float(item.unit_rate or 0.0),
                "amount": float(item.amount or 0.0),
                "entered_by": item.entered_by.name if item.entered_by else "",
                "created_at": created_at_str
            })

        return JsonResponse({"success": True, "data": data}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": f"Server Error: {str(e)}"}, status=500)


########################################################
# CREATE ELECTRICITY READING
########################################################
@csrf_exempt
def create_electricity_reading(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        body = json.loads(request.body)
        room_id = body.get("room_id")

        if not room_id:
            return JsonResponse({"success": False, "message": "Missing room_id parameter"}, status=400)

        try:
            room = Room.objects.get(id=room_id)
        except (Room.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Room configuration object not found"}, status=404)

        previous_reading = int(body.get("previous_reading") or 0)
        current_reading = int(body.get("current_reading") or 0)
        units_consumed = current_reading - previous_reading

        if units_consumed < 0:
            return JsonResponse({"success": False, "message": "Current reading cannot be less than previous reading"}, status=400)

        unit_rate = float(body.get("unit_rate") or 0.0)
        amount = units_consumed * unit_rate

        # Safe Date Normalizer
        raw_month = body.get("reading_month")
        if not raw_month:
            return JsonResponse({"success": False, "message": "Missing reading_month parameter"}, status=400)
        if len(str(raw_month)) == 7:
            raw_month = f"{raw_month}-01"

        entered_by = None
        if body.get("entered_by"):
            try:
                entered_by = Users.objects.get(id=body.get("entered_by"))
            except (Users.DoesNotExist, ValidationError):
                pass

        reading = ElectricityReading.objects.create(
            room=room,
            reading_month=raw_month,
            previous_reading=previous_reading,
            current_reading=current_reading,
            units_consumed=units_consumed,
            unit_rate=unit_rate,
            amount=amount,
            entered_by=entered_by
        )

        return JsonResponse({
            "success": True,
            "message": "Electricity Reading created successfully",
            "id": str(reading.id)
        }, status=201)

    except ValueError:
        return JsonResponse({"success": False, "message": "Invalid numeric digit values format supplied"}, status=400)
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# UPDATE ELECTRICITY READING
########################################################
@csrf_exempt
def update_electricity_reading(request, reading_id):
    if request.method != "PUT" and request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        body = json.loads(request.body)

        try:
            reading = ElectricityReading.objects.get(id=reading_id)
        except (ElectricityReading.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Target Reading document not found"}, status=404)

        if body.get("room_id"):
            try:
                reading.room = Room.objects.get(id=body.get("room_id"))
            except (Room.DoesNotExist, ValidationError):
                return JsonResponse({"success": False, "message": "Updated target Room not found"}, status=404)

        previous_reading = int(body.get("previous_reading", reading.previous_reading or 0))
        current_reading = int(body.get("current_reading", reading.current_reading or 0))
        units_consumed = current_reading - previous_reading

        if units_consumed < 0:
            return JsonResponse({"success": False, "message": "Recalculated current reading cannot be less than previous"}, status=400)

        unit_rate = float(body.get("unit_rate", reading.unit_rate or 0.0))
        amount = units_consumed * unit_rate

        raw_month = body.get("reading_month", reading.reading_month)
        if raw_month and len(str(raw_month)) == 7:
            raw_month = f"{raw_month}-01"

        reading.reading_month = raw_month
        reading.previous_reading = previous_reading
        reading.current_reading = current_reading
        reading.units_consumed = units_consumed
        reading.unit_rate = unit_rate
        reading.amount = amount
        reading.save()

        return JsonResponse({"success": True, "message": "Electricity Reading updated successfully"}, status=200)

    except ValueError:
        return JsonResponse({"success": False, "message": "Invalid number sequence arguments parsed"}, status=400)
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# DELETE ELECTRICITY READING
########################################################
@csrf_exempt
def delete_electricity_reading(request, reading_id):
    if request.method != "DELETE" and request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        try:
            reading = ElectricityReading.objects.get(id=reading_id)
        except (ElectricityReading.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Reading log signature does not exist"}, status=404)

        reading.delete()
        return JsonResponse({"success": True, "message": "Electricity Reading deleted successfully"}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# ELECTRICITY BY ROOM
########################################################
@csrf_exempt
def electricity_by_room(request, room_id):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        readings = ElectricityReading.objects.filter(room_id=room_id).order_by("-reading_month")

        data = []
        for item in readings:
            reading_month_str = (
                item.reading_month.strftime("%Y-%m-%d")
                if isinstance(item.reading_month, (date, date))
                else str(item.reading_month or "")
            )

            data.append({
                "id": str(item.id),
                "reading_month": reading_month_str,
                "previous_reading": int(item.previous_reading or 0),
                "current_reading": int(item.current_reading or 0),
                "units_consumed": int(item.units_consumed or 0),
                "unit_rate": float(item.unit_rate or 0.0),
                "amount": float(item.amount or 0.0),
            })

        return JsonResponse({"success": True, "data": data}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# LIST BILLS
########################################################
@csrf_exempt
def bills_list(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        bills = Bill.objects.select_related(
            "assignment",
            "assignment__tenant"
        ).prefetch_related(
            "charges"
        ).order_by("-bill_month")

        data = []
        for bill in bills:
            charges = [
                {
                    "id": str(c.id),
                    "charge_name": c.charge_name,
                    "charge_amount": float(c.charge_amount or 0.0),
                    "notes": c.notes,
                }
                for c in bill.charges.all()
            ]

            bill_month_str = (
                bill.bill_month.strftime("%Y-%m-%d")
                if isinstance(bill.bill_month, (date, date))
                else str(bill.bill_month or "")
            )
            due_date_str = (
                bill.due_date.strftime("%Y-%m-%d")
                if isinstance(bill.due_date, (date, date))
                else str(bill.due_date or "")
            )

            data.append({
                "id": str(bill.id),
                "assignment_id": str(bill.assignment.id) if bill.assignment else None,
                "tenant_name": bill.assignment.tenant.name if (bill.assignment and bill.assignment.tenant) else "Unknown Tenant",
                "bill_month": bill_month_str,
                "billing_period_start": bill_month_str,
                "rent_amount": float(bill.rent_amount or 0.0),
                "electricity_amount": float(bill.electricity_amount or 0.0),
                "additional_amount": float(bill.additional_amount or 0.0),
                "additional_charges": float(bill.additional_amount or 0.0),
                "total_amount": float(bill.total_amount or 0.0),
                "due_date": due_date_str,
                "status": bill.status or "pending",
                "charges": charges,
            })

        return JsonResponse({"success": True, "data": data}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": f"Server Error: {str(e)}"}, status=500)


########################################################
# CREATE BILL
########################################################
@csrf_exempt
def create_bill(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        body = json.loads(request.body)
        assignment_id = body.get("assignment_id")

        if not assignment_id:
            return JsonResponse({"success": False, "message": "Missing assignment_id parameter"}, status=400)

        try:
            assignment = TenantAssignment.objects.get(id=assignment_id)
        except (TenantAssignment.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Active Tenant Assignment entry not found"}, status=404)

        rent_amount = float(body.get("rent_amount") if body.get("rent_amount") else assignment.final_rent)
        electricity_amount = float(body.get("electricity_amount") or 0.0)
        additional_amount = float(body.get("additional_charges") or body.get("additional_amount") or 0.0)
        total_amount = rent_amount + electricity_amount + additional_amount

        raw_month = body.get("bill_month") or body.get("billing_period_start")
        if not raw_month:
            return JsonResponse({"success": False, "message": "Missing bill_month date parameter"}, status=400)

        if len(str(raw_month)) == 7:
            raw_month = f"{raw_month}-01"

        bill = Bill.objects.create(
            assignment=assignment,
            bill_month=raw_month,
            rent_amount=rent_amount,
            electricity_amount=electricity_amount,
            additional_amount=additional_amount,
            total_amount=total_amount,
            due_date=body.get("due_date"),
            status="pending"
        )

        return JsonResponse({
            "success": True,
            "message": "Bill created successfully",
            "bill_id": str(bill.id)
        }, status=201)

    except ValueError:
        return JsonResponse({"success": False, "message": "Invalid numeric input formats supplied"}, status=400)
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# UPDATE BILL
########################################################
@csrf_exempt
def update_bill(request, bill_id):
    if request.method != "PUT" and request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        body = json.loads(request.body)

        try:
            bill = Bill.objects.get(id=bill_id)
        except (Bill.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Target Bill document not found"}, status=404)

        if "rent_amount" in body and str(body.get("rent_amount")).strip() != "":
            bill.rent_amount = float(body.get("rent_amount"))

        if "electricity_amount" in body and str(body.get("electricity_amount")).strip() != "":
            bill.electricity_amount = float(body.get("electricity_amount"))

        if "additional_amount" in body and str(body.get("additional_amount")).strip() != "":
            bill.additional_amount = float(body.get("additional_amount"))
        elif "additional_charges" in body and str(body.get("additional_charges")).strip() != "":
            bill.additional_amount = float(body.get("additional_charges"))

        bill.total_amount = float(bill.rent_amount) + float(bill.electricity_amount) + float(bill.additional_amount)

        if "due_date" in body and body.get("due_date"):
            bill.due_date = body.get("due_date")

        if "status" in body:
            bill.status = body.get("status")

        bill.save()

        return JsonResponse({
            "success": True,
            "message": "Bill updated successfully",
            "total_amount": float(bill.total_amount)
        }, status=200)

    except ValueError:
        return JsonResponse({"success": False, "message": "Invalid currency numeric parameter syntax structure"}, status=400)
    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# DELETE BILL
########################################################
@csrf_exempt
def delete_bill(request, bill_id):
    if request.method != "DELETE" and request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        try:
            bill = Bill.objects.get(id=bill_id)
        except (Bill.DoesNotExist, ValidationError):
            return JsonResponse({"success": False, "message": "Target Bill document does not exist"}, status=404)

        bill.delete()
        return JsonResponse({"success": True, "message": "Bill deleted successfully"}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# LIST ADDITIONAL CHARGES
########################################################
@csrf_exempt
def additional_charges_list(request):
    if request.method != "GET":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        charges = AdditionalCharge.objects.select_related("bill")

        data = []
        for c in charges:
            data.append({
                "id": str(c.id),
                "bill_id": str(c.bill.id) if c.bill else None,
                "charge_name": c.charge_name or "Unnamed Charge",
                "charge_amount": float(c.charge_amount or 0.0),
                "notes": c.notes or "",
            })

        return JsonResponse({"success": True, "data": data}, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": f"Server Error: {str(e)}"}, status=500)


########################################################
# CREATE ADDITIONAL CHARGE
########################################################
@csrf_exempt
def create_additional_charge(request):
    if request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        body = json.loads(request.body)
        bill_id = body.get("bill_id")

        if not bill_id:
            return JsonResponse({"success": False, "message": "Missing bill_id parameter"}, status=400)

        with transaction.atomic():
            try:
                bill = Bill.objects.select_for_update().get(id=bill_id)
            except (Bill.DoesNotExist, ValidationError):
                return JsonResponse({"success": False, "message": "Target Bill statement could not be found"}, status=404)

            try:
                raw_amount = body.get("charge_amount") or 0.0
                charge_amount = float(raw_amount)
            except ValueError:
                return JsonResponse({"success": False, "message": "Charge amount must be a valid numeric calculation"}, status=400)

            charge = AdditionalCharge.objects.create(
                bill=bill,
                charge_name=body.get("charge_name", "Miscellaneous Charge").strip(),
                charge_amount=charge_amount,
                notes=body.get("notes", "").strip()
            )

            bill.additional_amount = float(bill.additional_amount or 0.0) + charge_amount
            bill.total_amount = float(bill.total_amount or 0.0) + charge_amount
            bill.save()

            return JsonResponse({
                "success": True,
                "message": "Charge applied to bill successfully",
                "id": str(charge.id),
                "new_bill_total": float(bill.total_amount)
            }, status=201)

    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)


########################################################
# DELETE ADDITIONAL CHARGE
########################################################
@csrf_exempt
def delete_additional_charge(request, charge_id):
    if request.method != "DELETE" and request.method != "POST":
        return JsonResponse({"success": False, "message": "Method Not Allowed"}, status=405)

    try:
        with transaction.atomic():
            try:
                charge = AdditionalCharge.objects.get(id=charge_id)
            except (AdditionalCharge.DoesNotExist, ValidationError):
                return JsonResponse({"success": False, "message": "Target Additional Charge record not found"}, status=404)

            bill = charge.bill
            if bill:
                bill = Bill.objects.select_for_update().get(id=bill.id)
                amt = float(charge.charge_amount or 0.0)
                bill.additional_amount = max(0.0, float(bill.additional_amount or 0.0) - amt)
                bill.total_amount = max(0.0, float(bill.total_amount or 0.0) - amt)
                bill.save()

            charge.delete()
            return JsonResponse({
                "success": True,
                "message": "Charge removed and ledger balanced successfully",
                "new_bill_total": float(bill.total_amount) if bill else 0.0
            }, status=200)

    except Exception as e:
        return JsonResponse({"success": False, "message": str(e)}, status=500)
########################################################
# CREATE PAYMENT
########################################################

@csrf_exempt
def create_payment(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            bill = Bill.objects.get(
                id=body.get("bill_id")
            )

            received_by = None

            if body.get("received_by"):

                received_by = Users.objects.get(
                    id=body.get("received_by")
                )

            payment = Payment.objects.create(

                bill=bill,

                amount_paid=
                    body.get(
                        "amount_paid"
                    ),

                payment_mode=
                    body.get(
                        "payment_mode"
                    ),

                utr_number=
                    body.get(
                        "utr_number",
                        ""
                    ),

                paid_at=
                    timezone.now(),

                received_by=
                    received_by
            )

            ################################################
            # UPDATE BILL STATUS
            ################################################

            total_paid = Payment.objects.filter(

                bill=bill

            ).aggregate(

                total=Sum("amount_paid")

            )["total"] or 0

            if total_paid == 0:

                bill.status = "pending"

            elif total_paid < bill.total_amount:

                bill.status = "partial"

            elif total_paid >= bill.total_amount:

                bill.status = "paid"

            bill.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Payment added successfully",

                "id":

                    str(payment.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False,

        "message":

            "Invalid Request"

    })
########################################################
# DELETE PAYMENT
########################################################

@csrf_exempt
def delete_payment(
    request,
    payment_id
):

    if request.method == "DELETE":

        try:

            payment = Payment.objects.get(
                id=payment_id
            )

            bill = payment.bill

            payment.delete()

            total_paid = Payment.objects.filter(

                bill=bill

            ).aggregate(

                total=Sum("amount_paid")

            )["total"] or 0

            if total_paid == 0:

                bill.status = "pending"

            elif total_paid < bill.total_amount:

                bill.status = "partial"

            else:

                bill.status = "paid"

            bill.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Payment deleted successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# PAYMENT TRANSACTIONS LIST
########################################################

@csrf_exempt
def payment_transactions_list(request):

    if request.method == "GET":

        transactions = (

            PaymentTransaction.objects

            .select_related(
                "payment",
                "payment__bill",
                "payment__bill__assignment",
                "payment__bill__assignment__tenant"
            )

            .order_by("-created_at")
        )

        data = []

        for item in transactions:

            data.append({

                "id":
                    str(item.id),

                "payment_id":
                    str(item.payment.id),

                "tenant_name":

                    item.payment.bill
                    .assignment
                    .tenant
                    .name,

                "gateway_name":
                    item.gateway_name,

                "gateway_order_id":
                    item.gateway_order_id,

                "gateway_payment_id":
                    item.gateway_payment_id,

                "transaction_status":
                    item.transaction_status,

                "amount":
                    float(item.amount),

                "currency":
                    item.currency,

                "created_at":

                    item.created_at.strftime(
                        "%d-%m-%Y %H:%M"
                    ),
            })

        return JsonResponse({

            "success": True,

            "data":
                data

        })

    return JsonResponse({

        "success": False

    })
########################################################
# CREATE PAYMENT TRANSACTION
########################################################

@csrf_exempt
def create_payment_transaction(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            payment = Payment.objects.get(

                id=body.get("payment_id")

            )

            transaction = (

                PaymentTransaction.objects.create(

                    payment=payment,

                    gateway_name=
                        body.get(
                            "gateway_name"
                        ),

                    gateway_order_id=
                        body.get(
                            "gateway_order_id"
                        ),

                    gateway_payment_id=
                        body.get(
                            "gateway_payment_id"
                        ),

                    gateway_signature=
                        body.get(
                            "gateway_signature"
                        ),

                    transaction_status=
                        body.get(
                            "transaction_status",
                            "success"
                        ),

                    amount=
                        body.get(
                            "amount"
                        ),

                    currency=
                        body.get(
                            "currency",
                            "INR"
                        ),

                    gateway_response=
                        body.get(
                            "gateway_response",
                            {}
                        )
                )
            )

            return JsonResponse({

                "success": True,

                "message":

                    "Transaction saved",

                "id":

                    str(transaction.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# CREATE PAYMENT TRANSACTION
########################################################

@csrf_exempt
def create_payment_transaction(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            payment = Payment.objects.get(

                id=body.get("payment_id")

            )

            transaction = (

                PaymentTransaction.objects.create(

                    payment=payment,

                    gateway_name=
                        body.get(
                            "gateway_name"
                        ),

                    gateway_order_id=
                        body.get(
                            "gateway_order_id"
                        ),

                    gateway_payment_id=
                        body.get(
                            "gateway_payment_id"
                        ),

                    gateway_signature=
                        body.get(
                            "gateway_signature"
                        ),

                    transaction_status=
                        body.get(
                            "transaction_status",
                            "success"
                        ),

                    amount=
                        body.get(
                            "amount"
                        ),

                    currency=
                        body.get(
                            "currency",
                            "INR"
                        ),

                    gateway_response=
                        body.get(
                            "gateway_response",
                            {}
                        )
                )
            )

            return JsonResponse({

                "success": True,

                "message":

                    "Transaction saved",

                "id":

                    str(transaction.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# CREATE COMPLAINT
########################################################

@csrf_exempt
def create_complaint(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            tenant = Users.objects.get(
                id=body.get("tenant_id")
            )

            assignment = TenantAssignment.objects.get(
                id=body.get("assignment_id")
            )

            assigned_to = None

            if body.get("assigned_to"):

                assigned_to = Users.objects.get(
                    id=body.get("assigned_to")
                )

            complaint = Complaint.objects.create(

                tenant=tenant,

                assignment=assignment,

                title=
                    body.get("title"),

                description=
                    body.get("description"),

                priority=
                    body.get(
                        "priority",
                        "medium"
                    ),

                status="open",

                assigned_to=
                    assigned_to
            )

            return JsonResponse({

                "success": True,

                "message":

                    "Complaint created successfully",

                "id":

                    str(complaint.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# UPDATE COMPLAINT
########################################################

@csrf_exempt
def update_complaint(
    request,
    complaint_id
):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            complaint = Complaint.objects.get(
                id=complaint_id
            )

            complaint.title = body.get(
                "title",
                complaint.title
            )

            complaint.description = body.get(
                "description",
                complaint.description
            )

            complaint.priority = body.get(
                "priority",
                complaint.priority
            )

            complaint.status = body.get(
                "status",
                complaint.status
            )

            if body.get("assigned_to"):

                complaint.assigned_to = Users.objects.get(

                    id=body.get("assigned_to")

                )

            if complaint.status in [

                "resolved",

                "closed"

            ]:

                complaint.resolved_at = timezone.now()

            complaint.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Complaint updated successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# DELETE COMPLAINT
########################################################

@csrf_exempt
def delete_complaint(
    request,
    complaint_id
):

    if request.method == "DELETE":

        try:

            complaint = Complaint.objects.get(
                id=complaint_id
            )

            complaint.delete()

            return JsonResponse({

                "success": True,

                "message":

                    "Complaint deleted successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# MAINTENANCE REQUESTS LIST
########################################################

@csrf_exempt
def maintenance_requests_list(request):

    if request.method == "GET":

        requests = MaintenanceRequest.objects.select_related(

            "complaint",

            "complaint__tenant",

            "assigned_to"

        ).order_by("-created_at")

        data = []

        for item in requests:

            data.append({

                "id":
                    str(item.id),

                "complaint_id":
                    str(item.complaint.id),

                "tenant_name":

                    item.complaint
                    .tenant
                    .name,

                "complaint_title":

                    item.complaint
                    .title,

                "assigned_to":

                    item.assigned_to.name

                    if item.assigned_to

                    else "",

                "notes":
                    item.notes,

                "status":
                    item.status,

                "created_at":

                    item.created_at.strftime(
                        "%d-%m-%Y %H:%M"
                    ),

                "completed_at":

                    item.completed_at.strftime(
                        "%d-%m-%Y %H:%M"
                    )

                    if item.completed_at

                    else None,
            })

        return JsonResponse({

            "success": True,

            "data":
                data

        })

    return JsonResponse({

        "success": False

    })
########################################################
# CREATE MAINTENANCE REQUEST
########################################################

@csrf_exempt
def create_maintenance_request(request):

    if request.method == "POST":

        try:

            body = json.loads(request.body)

            complaint = Complaint.objects.get(

                id=body.get("complaint_id")

            )

            assigned_to = None

            if body.get("assigned_to"):

                assigned_to = Users.objects.get(

                    id=body.get("assigned_to")

                )

            maintenance = (

                MaintenanceRequest.objects.create(

                    complaint=complaint,

                    assigned_to=
                        assigned_to,

                    notes=
                        body.get(
                            "notes",
                            ""
                        ),

                    status="pending"
                )
            )

            complaint.status = "in_progress"

            complaint.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Maintenance request created",

                "id":

                    str(maintenance.id)

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# UPDATE MAINTENANCE REQUEST
########################################################

@csrf_exempt
def update_maintenance_request(
    request,
    request_id
):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            maintenance = (

                MaintenanceRequest.objects.get(

                    id=request_id

                )
            )

            maintenance.notes = body.get(

                "notes",

                maintenance.notes

            )

            maintenance.status = body.get(

                "status",

                maintenance.status

            )

            if body.get("assigned_to"):

                maintenance.assigned_to = Users.objects.get(

                    id=body.get("assigned_to")

                )

            if maintenance.status == "completed":

                maintenance.completed_at = timezone.now()

                maintenance.complaint.status = "resolved"

                maintenance.complaint.resolved_at = timezone.now()

                maintenance.complaint.save()

            maintenance.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Maintenance updated successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })
########################################################
# UPDATE MAINTENANCE REQUEST
########################################################

@csrf_exempt
def update_maintenance_request(
    request,
    request_id
):

    if request.method == "PUT":

        try:

            body = json.loads(request.body)

            maintenance = (

                MaintenanceRequest.objects.get(

                    id=request_id

                )
            )

            maintenance.notes = body.get(

                "notes",

                maintenance.notes

            )

            maintenance.status = body.get(

                "status",

                maintenance.status

            )

            if body.get("assigned_to"):

                maintenance.assigned_to = Users.objects.get(

                    id=body.get("assigned_to")

                )

            if maintenance.status == "completed":

                maintenance.completed_at = timezone.now()

                maintenance.complaint.status = "resolved"

                maintenance.complaint.resolved_at = timezone.now()

                maintenance.complaint.save()

            maintenance.save()

            return JsonResponse({

                "success": True,

                "message":

                    "Maintenance updated successfully"

            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":

                    str(e)

            })

    return JsonResponse({

        "success": False

    })

########################################################
# DOCUMENTS LIST
########################################################

@csrf_exempt
def documents_list(request):

    if request.method == "GET":

        documents = Document.objects.select_related(
            "tenant",
            "assignment"
        ).order_by("-uploaded_at")

        data = []

        for doc in documents:

            data.append({

                "id": str(doc.id),

                "tenant_id":
                    str(doc.tenant.id),

                "tenant_name":
                    doc.tenant.name,

                "assignment_id":
                    str(doc.assignment.id),

                "document_type":
                    doc.document_type,

                "document_name":
                    doc.document_name,

                "document_url":
                    doc.document_url,

                "uploaded_at":
                    doc.uploaded_at.strftime(
                        "%d-%m-%Y %H:%M"
                    ),
            })

        return JsonResponse({
            "success": True,
            "data": data
        })

    return JsonResponse({
        "success": False,
        "message": "Invalid Request"
    })


########################################################
# DOCUMENT DETAIL
########################################################

@csrf_exempt
def document_detail(request, document_id):

    if request.method == "GET":

        try:

            doc = Document.objects.select_related(
                "tenant",
                "assignment"
            ).get(
                id=document_id
            )

            return JsonResponse({

                "success": True,

                "data": {

                    "id":
                        str(doc.id),

                    "tenant_id":
                        str(doc.tenant.id),

                    "tenant_name":
                        doc.tenant.name,

                    "assignment_id":
                        str(doc.assignment.id),

                    "document_type":
                        doc.document_type,

                    "document_name":
                        doc.document_name,

                    "document_url":
                        doc.document_url,

                    "uploaded_at":
                        doc.uploaded_at.strftime(
                            "%d-%m-%Y %H:%M"
                        ),
                }
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)
            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"
    })
########################################################
# CREATE DOCUMENT
########################################################

@csrf_exempt
def create_document(request):

    if request.method == "POST":

        try:

            body = json.loads(
                request.body
            )

            tenant = Users.objects.get(
                id=body.get(
                    "tenant_id"
                )
            )

            assignment = (
                TenantAssignment.objects.get(
                    id=body.get(
                        "assignment_id"
                    )
                )
            )

            doc = Document.objects.create(

                tenant=tenant,

                assignment=assignment,

                document_type=
                    body.get(
                        "document_type"
                    ),

                document_name=
                    body.get(
                        "document_name"
                    ),

                document_url=
                    body.get(
                        "document_url"
                    ),
            )

            return JsonResponse({

                "success": True,

                "message":
                    "Document uploaded successfully",

                "id":
                    str(doc.id)
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)
            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"
    })
########################################################
# UPDATE DOCUMENT
########################################################

@csrf_exempt
def update_document(
    request,
    document_id
):

    if request.method == "PUT":

        try:

            body = json.loads(
                request.body
            )

            doc = Document.objects.get(
                id=document_id
            )

            if body.get(
                "tenant_id"
            ):

                doc.tenant = (
                    Users.objects.get(
                        id=body.get(
                            "tenant_id"
                        )
                    )
                )

            if body.get(
                "assignment_id"
            ):

                doc.assignment = (
                    TenantAssignment.objects.get(
                        id=body.get(
                            "assignment_id"
                        )
                    )
                )

            doc.document_type = (
                body.get(
                    "document_type",
                    doc.document_type
                )
            )

            doc.document_name = (
                body.get(
                    "document_name",
                    doc.document_name
                )
            )

            doc.document_url = (
                body.get(
                    "document_url",
                    doc.document_url
                )
            )

            doc.save()

            return JsonResponse({

                "success": True,

                "message":
                    "Document updated successfully"
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)
            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"
    })
########################################################
# DELETE DOCUMENT
########################################################

@csrf_exempt
def delete_document(
    request,
    document_id
):

    if request.method == "DELETE":

        try:

            doc = Document.objects.get(
                id=document_id
            )

            doc.delete()

            return JsonResponse({

                "success": True,

                "message":
                    "Document deleted successfully"
            })

        except Exception as e:

            return JsonResponse({

                "success": False,

                "message":
                    str(e)
            })

    return JsonResponse({

        "success": False,

        "message":
            "Invalid Request"
    })
# =====================================================
# CREATE VACATE NOTICE (Tenant)
# =====================================================

@csrf_exempt
def create_vacate_notice(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body)

        tenant_id = data.get("tenant")
        assignment_id = data.get("assignment")
        notice_date = data.get("notice_date")
        vacate_date = data.get("vacate_date")
        reason = data.get("reason", "")

        if not tenant_id or not assignment_id:
            return JsonResponse(
                {"error": "tenant and assignment are required"},
                status=400
            )

        # prevent duplicate pending notice
        if VacateNotice.objects.filter(
            tenant_id=tenant_id,
            assignment_id=assignment_id,
            status="pending"
        ).exists():
            return JsonResponse(
                {"error": "Vacate notice already exists"},
                status=400
            )

        notice = VacateNotice.objects.create(
            tenant_id=tenant_id,
            assignment_id=assignment_id,
            notice_date=notice_date,
            vacate_date=vacate_date,
            reason=reason
        )

        return JsonResponse({
            "id": str(notice.id),
            "message": "Vacate notice created successfully"
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =====================================================
# LIST VACATE NOTICES
# =====================================================

def list_vacate_notices(request):
    notices = VacateNotice.objects.select_related("tenant", "assignment").all()

    data = []
    for n in notices:
        data.append({
            "id": str(n.id),
            "tenant": str(n.tenant_id),
            "assignment": str(n.assignment_id),
            "notice_date": n.notice_date,
            "vacate_date": n.vacate_date,
            "reason": n.reason,
            "status": n.status,
            "approved_by": str(n.approved_by_id) if n.approved_by_id else None,
        })

    return JsonResponse(data, safe=False)


# =====================================================
# APPROVE VACATE NOTICE
# =====================================================

@csrf_exempt
def approve_vacate_notice(request, notice_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        notice = VacateNotice.objects.get(id=notice_id)

        notice.status = "approved"
        notice.approved_by_id = request.POST.get("approved_by")
        notice.save()

        return JsonResponse({"message": "Vacate approved"})

    except VacateNotice.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)


# =====================================================
# REJECT VACATE NOTICE
# =====================================================

@csrf_exempt
def reject_vacate_notice(request, notice_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        notice = VacateNotice.objects.get(id=notice_id)

        notice.status = "rejected"
        notice.approved_by_id = request.POST.get("approved_by")
        notice.save()

        return JsonResponse({"message": "Vacate rejected"})

    except VacateNotice.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)


# =====================================================
# COMPLETE VACATE (Final move-out)
# =====================================================

@csrf_exempt
def complete_vacate_notice(request, notice_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        notice = VacateNotice.objects.get(id=notice_id)

        notice.status = "completed"
        notice.save()

        # update assignment
        assignment = notice.assignment
        assignment.status = "vacated"
        assignment.rent_end_date = timezone.now().date()
        assignment.save()

        return JsonResponse({"message": "Vacate completed"})

    except VacateNotice.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)


# =====================================================
# CREATE SINGLE NOTIFICATION
# =====================================================

@csrf_exempt
def create_notification(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body)

        user_id = data.get("user")
        title = data.get("title")
        message = data.get("message")

        if not user_id or not title:
            return JsonResponse({"error": "user and title required"}, status=400)

        notification = Notification.objects.create(
            user_id=user_id,
            title=title,
            message=message or ""
        )

        return JsonResponse({
            "id": str(notification.id),
            "message": "Notification created"
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =====================================================
# BULK NOTIFICATIONS (ROLE-BASED)
# =====================================================

@csrf_exempt
def create_bulk_notifications(request):
    """
    Send notifications to:
    - all users
    - by role (owner/manager/tenant)
    """
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body)

        title = data.get("title")
        message = data.get("message", "")
        role = data.get("role")   # optional
        user_ids = data.get("user_ids")  # optional list

        if not title:
            return JsonResponse({"error": "title required"}, status=400)

        users = Users.objects.all()

        # filter by role
        if role:
            users = users.filter(role=role)

        # filter by specific users
        if user_ids:
            users = users.filter(id__in=user_ids)

        notifications = [
            Notification(
                user=u,
                title=title,
                message=message
            )
            for u in users
        ]

        Notification.objects.bulk_create(notifications)

        return JsonResponse({
            "message": "Bulk notifications sent",
            "count": len(notifications)
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# =====================================================
# GET NOTIFICATIONS (ROLE BASED FILTERING)
# =====================================================

def list_notifications(request):
    """
    Query params:
    - user_id
    - role (optional filter via user.role)
    - unread=true
    """

    user_id = request.GET.get("user_id")
    role = request.GET.get("role")
    unread = request.GET.get("unread")

    notifications = Notification.objects.select_related("user").all()

    if user_id:
        notifications = notifications.filter(user_id=user_id)

    if role:
        notifications = notifications.filter(user__role=role)

    if unread == "true":
        notifications = notifications.filter(is_read=False)

    data = []
    for n in notifications.order_by("-created_at"):
        data.append({
            "id": str(n.id),
            "user": str(n.user_id),
            "title": n.title,
            "message": n.message,
            "is_read": n.is_read,
            "created_at": n.created_at
        })

    return JsonResponse(data, safe=False)


# =====================================================
# MARK AS READ
# =====================================================

@csrf_exempt
def mark_as_read(request, notification_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = True
        notification.save()

        return JsonResponse({"message": "Marked as read"})

    except Notification.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)


# =====================================================
# MARK AS UNREAD
# =====================================================

@csrf_exempt
def mark_as_unread(request, notification_id):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = False
        notification.save()

        return JsonResponse({"message": "Marked as unread"})

    except Notification.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)


# =====================================================
# DELETE NOTIFICATION
# =====================================================

@csrf_exempt
def delete_notification(request, notification_id):
    if request.method != "DELETE":
        return JsonResponse({"error": "Only DELETE allowed"}, status=405)

    try:
        notification = Notification.objects.get(id=notification_id)
        notification.delete()

        return JsonResponse({"message": "Deleted successfully"})

    except Notification.DoesNotExist:
        return JsonResponse({"error": "Not found"}, status=404)

# =====================================================
# GET SETTINGS (GLOBAL - SINGLE ROW)
# =====================================================

def get_settings(request):
    setting = Setting.objects.first()

    if not setting:
        return JsonResponse({"error": "Settings not configured"}, status=404)

    return JsonResponse({
        "id": str(setting.id),
        "company_name": setting.company_name,
        "company_phone": setting.company_phone,
        "company_email": setting.company_email,
        "company_address": setting.company_address,
        "default_notice_days": setting.default_notice_days,
        "default_electricity_rate": str(setting.default_electricity_rate),
        "updated_at": setting.updated_at
    })


# =====================================================
# UPDATE SETTINGS (ADMIN ONLY LOGIC OPTIONAL)
# =====================================================

@csrf_exempt
def update_settings(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        data = json.loads(request.body)

        setting, created = Setting.objects.get_or_create(id=data.get("id"))

        setting.company_name = data.get("company_name", setting.company_name)
        setting.company_phone = data.get("company_phone", setting.company_phone)
        setting.company_email = data.get("company_email", setting.company_email)
        setting.company_address = data.get("company_address", setting.company_address)
        setting.default_notice_days = data.get("default_notice_days", setting.default_notice_days)
        setting.default_electricity_rate = data.get(
            "default_electricity_rate",
            setting.default_electricity_rate
        )

        setting.save()

        return JsonResponse({
            "message": "Settings updated successfully"
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)

@csrf_exempt
def profile_view(request):
    try:
        user_id = request.GET.get("user_id")

        if not user_id:
            return JsonResponse({"error": "user_id required"}, status=400)

        user = Users.objects.get(id=user_id)

        # ======================
        # GET PROFILE
        # ======================
        if request.method == "GET":
            return JsonResponse({
                "success": True,
                "data": {
                    "id": str(user.id),
                    "name": user.name,
                    "phone": user.phone,
                    "email": user.email,
                    "role": user.role,
                    "status": user.status,
                }
            })

        # ======================
        # UPDATE PROFILE (ONLY OWNER)
        # ======================
        if request.method == "PUT":
            if user.role != "owner":
                return JsonResponse(
                    {"error": "Only owner can update profile"},
                    status=403
                )

            data = json.loads(request.body)

            user.name = data.get("name", user.name)
            user.email = data.get("email", user.email)
            user.phone = data.get("phone", user.phone)

            user.save()

            return JsonResponse({
                "success": True,
                "message": "Profile updated successfully"
            })

        return JsonResponse({"error": "Method not allowed"}, status=405)

    except Users.DoesNotExist:
        return JsonResponse({"error": "User not found"}, status=404)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt
def managers_api(request):
    ####################################################
    # GET -> LIST / DETAIL
    ####################################################
    if request.method == "GET":
        manager_id = request.GET.get("id")
        owner_id = request.GET.get("owner_id")

        # -------------------------
        # DETAIL VARIANT
        # -------------------------
        if manager_id:
            try:
                manager = Users.objects.get(
                    id=manager_id,
                    role="manager",
                    status="active",
                )
                return JsonResponse({
                    "success": True,
                    "data": {
                        "id": str(manager.id),
                        "name": manager.name,
                        "email": manager.email,
                        "phone": manager.phone,
                        "status": manager.status,
                        "created_at": manager.created_at,
                    }
                })
            except (Users.DoesNotExist, ValidationError):
                return JsonResponse({
                    "success": False,
                    "error": "Manager not found",
                }, status=404)

        # -------------------------
        # LIST VARIANT
        # -------------------------
        managers = Users.objects.filter(role="manager", status="active")

        # 🛡️ FIXED: Only filter by owner_id if it's present AND not an empty string
        # Since your original model has no owner field, if you ever add one later, this protects it.
        if owner_id and owner_id.strip():
            # If your model doesn't have an owner field at all right now,
            # comment these two lines out to avoid query structural errors.
            pass

        data = [{
            "id": str(m.id),
            "name": m.name,
            "email": m.email,
            "phone": m.phone,
            "status": m.status,
            "created_at": m.created_at,
        } for m in managers]

        return JsonResponse({
            "success": True,
            "count": len(data),
            "data": data,
        })

    ####################################################
    # POST -> CREATE
    ####################################################
    elif request.method == "POST":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "error": "Invalid JSON"}, status=400)

        name = body.get("name")
        email = body.get("email")
        phone = body.get("phone")

        if not name:
            return JsonResponse({"success": False, "error": "Name required"}, status=400)

        if not phone:
            return JsonResponse({"success": False, "error": "Phone number required"}, status=400)

        # Handle unique email check cleanly
        if email and email.strip():
            email = email.strip().lower()
            if Users.objects.filter(email=email).exists():
                return JsonResponse({"success": False, "error": "Email already exists"}, status=400)
        else:
            email = None

        if Users.objects.filter(phone=phone).exists():
            return JsonResponse({"success": False, "error": "Phone number already registered"}, status=400)

        # 🛡️ FIXED: Removed 'owner=owner' to match your exact structural model constraints!
        manager = Users.objects.create(
            name=name,
            email=email,
            phone=phone,
            role="manager",
            status="active"
        )

        return JsonResponse({
            "success": True,
            "message": "Manager created",
            "id": str(manager.id),
        })

    ####################################################
    # PUT -> UPDATE
    ####################################################
    elif request.method == "PUT":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "error": "Invalid JSON"}, status=400)

        manager_id = body.get("id")

        try:
            manager = Users.objects.get(
                id=manager_id,
                role="manager",
                status="active",
            )
        except (Users.DoesNotExist, ValidationError):
            return JsonResponse({
                "success": False,
                "error": "Manager not found",
            }, status=404)

        manager.name = body.get("name", manager.name)
        manager.phone = body.get("phone", manager.phone)
        manager.save()

        return JsonResponse({
            "success": True,
            "message": "Manager updated",
        })

    ####################################################
    # DELETE -> SOFT DELETE
    ####################################################
    elif request.method == "DELETE":
        try:
            body = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({"success": False, "error": "Invalid JSON"}, status=400)

        manager_id = body.get("id")

        try:
            manager = Users.objects.get(id=manager_id, role="manager")
        except (Users.DoesNotExist, ValidationError):
            return JsonResponse({
                "success": False,
                "error": "Manager not found",
            }, status=404)

        manager.status = "inactive"
        manager.save()

        return JsonResponse({
            "success": True,
            "message": "Manager deleted",
        })

    return JsonResponse({
        "success": False,
        "error": "Method not allowed",
    }, status=405)