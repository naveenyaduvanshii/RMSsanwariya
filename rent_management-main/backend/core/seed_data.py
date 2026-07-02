import os
import django
import datetime
import random
from decimal import Decimal

# Setup django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rent.models import Users, Building, Floor, Flat, Room, RentalUnit, TenantAssignment

def seed():
    print("Deleting existing test data...")
    # Clear existing test data to start fresh
    TenantAssignment.objects.filter(tenant__role="tenant", tenant__name__startswith="tenant").delete()
    Users.objects.filter(role="tenant", name__startswith="tenant").delete()
    Building.objects.filter(name="Alpha Tower").delete()
    
    print("Creating Building...")
    building = Building.objects.create(
        name="Alpha Tower",
        address="123 Main St",
        city="Mumbai",
        state="Maharashtra",
        pincode="400001",
        total_floors=2,
        description="Premium residential building"
    )

    print("Creating Floors...")
    floor1 = Floor.objects.create(building=building, floor_number=1, floor_name="First Floor")
    floor2 = Floor.objects.create(building=building, floor_number=2, floor_name="Second Floor")

    print("Creating Flats...")
    # Floor 1 flats
    flat101 = Flat.objects.create(building=building, floor=floor1, flat_number="101", capacity=2, base_rent=Decimal("15000.00"), allow_sharing=True)
    flat102 = Flat.objects.create(building=building, floor=floor1, flat_number="102", capacity=1, base_rent=Decimal("12000.00"), allow_sharing=False)
    # Floor 2 flats
    flat201 = Flat.objects.create(building=building, floor=floor2, flat_number="201", capacity=2, base_rent=Decimal("18000.00"), allow_sharing=True)
    flat202 = Flat.objects.create(building=building, floor=floor2, flat_number="202", capacity=1, base_rent=Decimal("16000.00"), allow_sharing=False)

    print("Creating Rooms...")
    # Rooms in flat 101
    room101A = Room.objects.create(building=building, floor=floor1, flat=flat101, room_number="101A", room_type="Single", capacity=2, base_rent=Decimal("8000.00"), allow_sharing=True)
    room101B = Room.objects.create(building=building, floor=floor1, flat=flat101, room_number="101B", room_type="Single", capacity=1, base_rent=Decimal("7000.00"), allow_sharing=False)
    # Rooms in flat 102
    room102A = Room.objects.create(building=building, floor=floor1, flat=flat102, room_number="102A", room_type="Single", capacity=1, base_rent=Decimal("6500.00"), allow_sharing=False)
    room102B = Room.objects.create(building=building, floor=floor1, flat=flat102, room_number="102B", room_type="Single", capacity=1, base_rent=Decimal("6000.00"), allow_sharing=False)

    print("Creating 10 dummy tenants...")
    tenants = []
    for i in range(1, 11):
        # Generate random unique phone and email to prevent key constraints issues
        phone = f"9876{random.randint(100000, 999999)}"
        email = f"tenant{i}_{random.randint(1000, 9999)}@example.com"
        
        # Ensure it doesn't already exist
        while Users.objects.filter(phone=phone).exists():
            phone = f"9876{random.randint(100000, 999999)}"
        while Users.objects.filter(email=email).exists():
            email = f"tenant{i}_{random.randint(1000, 9999)}@example.com"

        tenant = Users.objects.create(
            name=f"tenant{i}",
            phone=phone,
            email=email,
            role="tenant",
            status="active"
        )
        tenants.append(tenant)
        print(f"Created {tenant.name} (Phone: {phone}, Email: {email})")

    print("Retrieving auto-created RentalUnits...")
    # Flat 201 & 202 rental units
    ru_flat201 = RentalUnit.objects.get(unit_type="flat", flat=flat201)
    ru_flat202 = RentalUnit.objects.get(unit_type="flat", flat=flat202)

    # Room rental units
    ru_room101A = RentalUnit.objects.get(unit_type="room", room=room101A)
    ru_room101B = RentalUnit.objects.get(unit_type="room", room=room101B)
    ru_room102A = RentalUnit.objects.get(unit_type="room", room=room102A)
    ru_room102B = RentalUnit.objects.get(unit_type="room", room=room102B)

    print("Creating Tenant Assignments...")
    today = datetime.date.today()

    # Assign tenant1 & tenant2 to Room 101A (sharing)
    TenantAssignment.objects.create(
        tenant=tenants[0], rental_unit=ru_room101A, exclusive_occupancy=False,
        security_deposit=Decimal("4000.00"), final_rent=Decimal("4000.00"), rent_start_date=today, status="active"
    )
    TenantAssignment.objects.create(
        tenant=tenants[1], rental_unit=ru_room101A, exclusive_occupancy=False,
        security_deposit=Decimal("4000.00"), final_rent=Decimal("4000.00"), rent_start_date=today, status="active"
    )

    # Assign tenant3 to Room 101B
    TenantAssignment.objects.create(
        tenant=tenants[2], rental_unit=ru_room101B, exclusive_occupancy=True,
        security_deposit=Decimal("7000.00"), final_rent=Decimal("7000.00"), rent_start_date=today, status="active"
    )

    # Assign tenant4 to Room 102A
    TenantAssignment.objects.create(
        tenant=tenants[3], rental_unit=ru_room102A, exclusive_occupancy=True,
        security_deposit=Decimal("6500.00"), final_rent=Decimal("6500.00"), rent_start_date=today, status="active"
    )

    # Assign tenant5 & tenant6 to Flat 201 (sharing flat)
    TenantAssignment.objects.create(
        tenant=tenants[4], rental_unit=ru_flat201, exclusive_occupancy=False,
        security_deposit=Decimal("9000.00"), final_rent=Decimal("9000.00"), rent_start_date=today, status="active"
    )
    TenantAssignment.objects.create(
        tenant=tenants[5], rental_unit=ru_flat201, exclusive_occupancy=False,
        security_deposit=Decimal("9000.00"), final_rent=Decimal("9000.00"), rent_start_date=today, status="active"
    )

    # Assign tenant7 to Flat 202
    TenantAssignment.objects.create(
        tenant=tenants[6], rental_unit=ru_flat202, exclusive_occupancy=True,
        security_deposit=Decimal("16000.00"), final_rent=Decimal("16000.00"), rent_start_date=today, status="active"
    )

    print("Successfully seeded all dummy data!")

if __name__ == "__main__":
    seed()
