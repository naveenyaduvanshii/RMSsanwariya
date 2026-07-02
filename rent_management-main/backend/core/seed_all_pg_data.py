import os
import django
import datetime
import random
from decimal import Decimal

# Setup django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rent.models import Users, Building, Floor, Flat, Room, RentalUnit, TenantAssignment, ElectricityReading, Bill, Payment

def seed_all():
    print("Deleting all previous test data...")
    # Clean up completely
    Payment.objects.all().delete()
    Bill.objects.all().delete()
    ElectricityReading.objects.all().delete()
    TenantAssignment.objects.all().delete()
    RentalUnit.objects.all().delete()
    Room.objects.all().delete()
    Flat.objects.all().delete()
    Floor.objects.all().delete()
    Building.objects.filter(name__in=["Building 1", "Building 2", "Alpha Tower"]).delete()
    Users.objects.filter(role="tenant", name__startswith="tenant").delete()

    print("Creating Building 1 & Building 2...")
    b1 = Building.objects.create(
        name="Building 1", address="Sector 62, Noida", city="Noida", state="Uttar Pradesh", pincode="201301", total_floors=2, description="PG Block A"
    )
    b2 = Building.objects.create(
        name="Building 2", address="Sector 63, Noida", city="Noida", state="Uttar Pradesh", pincode="201301", total_floors=2, description="PG Block B"
    )

    print("Creating Floors...")
    b1_f1 = Floor.objects.create(building=b1, floor_number=1, floor_name="First Floor")
    b1_f2 = Floor.objects.create(building=b1, floor_number=2, floor_name="Second Floor")
    b2_f1 = Floor.objects.create(building=b2, floor_number=1, floor_name="First Floor")
    b2_f2 = Floor.objects.create(building=b2, floor_number=2, floor_name="Second Floor")

    print("Creating Flats...")
    # Building 1 Flats
    b1_flat101 = Flat.objects.create(building=b1, floor=b1_f1, flat_number="101", capacity=2, base_rent=Decimal("15000.00"), allow_sharing=True)
    b1_flat102 = Flat.objects.create(building=b1, floor=b1_f1, flat_number="102", capacity=1, base_rent=Decimal("12000.00"), allow_sharing=False)
    # Building 2 Flats
    b2_flat201 = Flat.objects.create(building=b2, floor=b2_f2, flat_number="201", capacity=2, base_rent=Decimal("18000.00"), allow_sharing=True)
    b2_flat202 = Flat.objects.create(building=b2, floor=b2_f2, flat_number="202", capacity=1, base_rent=Decimal("16000.00"), allow_sharing=False)

    print("Creating Rooms...")
    # Rooms in Building 1, Flat 101
    room101A = Room.objects.create(building=b1, floor=b1_f1, flat=b1_flat101, room_number="101A", room_type="Single", capacity=2, base_rent=Decimal("8000.00"), allow_sharing=True)
    room101B = Room.objects.create(building=b1, floor=b1_f1, flat=b1_flat101, room_number="101B", room_type="Single", capacity=1, base_rent=Decimal("7000.00"), allow_sharing=False)
    # Rooms in Building 1, Flat 102
    room102A = Room.objects.create(building=b1, floor=b1_f1, flat=b1_flat102, room_number="102A", room_type="Single", capacity=1, base_rent=Decimal("6500.00"), allow_sharing=False)
    room102B = Room.objects.create(building=b1, floor=b1_f1, flat=b1_flat102, room_number="102B", room_type="Single", capacity=1, base_rent=Decimal("6000.00"), allow_sharing=False)

    print("Creating 10 dummy tenants...")
    tenants = []
    for i in range(1, 11):
        phone = f"9876{random.randint(100000, 999999)}"
        email = f"tenant{i}_{random.randint(1000, 9999)}@example.com"
        while Users.objects.filter(phone=phone).exists():
            phone = f"9876{random.randint(100000, 999999)}"
        while Users.objects.filter(email=email).exists():
            email = f"tenant{i}_{random.randint(1000, 9999)}@example.com"

        tenant = Users.objects.create(
            name=f"tenant{i}", phone=phone, email=email, role="tenant", status="active"
        )
        tenants.append(tenant)

    print("Retrieving auto-created RentalUnits...")
    ru_flat201 = RentalUnit.objects.get(unit_type="flat", flat=b2_flat201)
    ru_flat202 = RentalUnit.objects.get(unit_type="flat", flat=b2_flat202)
    ru_room101A = RentalUnit.objects.get(unit_type="room", room=room101A)
    ru_room101B = RentalUnit.objects.get(unit_type="room", room=room101B)
    ru_room102A = RentalUnit.objects.get(unit_type="room", room=room102A)
    ru_room102B = RentalUnit.objects.get(unit_type="room", room=room102B)

    print("Creating Tenant Assignments...")
    # Building 1 Room 101A: tenant1 & tenant2 starting July 1, 2026
    ta1 = TenantAssignment.objects.create(
        tenant=tenants[0], rental_unit=ru_room101A, exclusive_occupancy=False,
        security_deposit=Decimal("4000.00"), final_rent=Decimal("4000.00"), rent_start_date=datetime.date(2026, 7, 1), status="active"
    )
    ta2 = TenantAssignment.objects.create(
        tenant=tenants[1], rental_unit=ru_room101A, exclusive_occupancy=False,
        security_deposit=Decimal("4000.00"), final_rent=Decimal("4000.00"), rent_start_date=datetime.date(2026, 7, 1), status="active"
    )
    # Building 1 Room 101B: tenant3 starting January 15, 2026
    ta3 = TenantAssignment.objects.create(
        tenant=tenants[2], rental_unit=ru_room101B, exclusive_occupancy=True,
        security_deposit=Decimal("7000.00"), final_rent=Decimal("7000.00"), rent_start_date=datetime.date(2026, 1, 15), status="active"
    )
    # Building 1 Room 102A: tenant4 starting February 1, 2026
    ta4 = TenantAssignment.objects.create(
        tenant=tenants[3], rental_unit=ru_room102A, exclusive_occupancy=True,
        security_deposit=Decimal("6500.00"), final_rent=Decimal("6500.00"), rent_start_date=datetime.date(2026, 2, 1), status="active"
    )
    # Building 2 Flat 201: tenant5 & tenant6 starting March 1, 2026
    ta5 = TenantAssignment.objects.create(
        tenant=tenants[4], rental_unit=ru_flat201, exclusive_occupancy=False,
        security_deposit=Decimal("9000.00"), final_rent=Decimal("9000.00"), rent_start_date=datetime.date(2026, 3, 1), status="active"
    )
    ta6 = TenantAssignment.objects.create(
        tenant=tenants[5], rental_unit=ru_flat201, exclusive_occupancy=False,
        security_deposit=Decimal("9000.00"), final_rent=Decimal("9000.00"), rent_start_date=datetime.date(2026, 3, 15), status="active"
    )
    # Building 2 Flat 202: tenant7 starting April 1, 2026
    ta7 = TenantAssignment.objects.create(
        tenant=tenants[6], rental_unit=ru_flat202, exclusive_occupancy=True,
        security_deposit=Decimal("16000.00"), final_rent=Decimal("16000.00"), rent_start_date=datetime.date(2026, 4, 1), status="active"
    )

    all_assignments = [ta1, ta2, ta3, ta4, ta5, ta6, ta7]
    assigned_room_ids = [room101A.id, room101B.id, room102A.id, room102B.id]

    billing_months = [
        datetime.date(2026, 1, 1),
        datetime.date(2026, 2, 1),
        datetime.date(2026, 3, 1),
        datetime.date(2026, 4, 1),
        datetime.date(2026, 5, 1),
        datetime.date(2026, 6, 1),
        datetime.date(2026, 7, 1),
    ]

    print("Generating Electricity Readings...")
    base_readings = {r_id: 1000 for r_id in assigned_room_ids}
    for month in billing_months:
        for r_id in assigned_room_ids:
            prev = base_readings[r_id]
            consumed = 100 + (month.month * 5)
            curr = prev + consumed
            base_readings[r_id] = curr
            
            rate = Decimal("10.00")
            amt = Decimal(str(consumed)) * rate
            ElectricityReading.objects.create(
                room_id=r_id, reading_month=month, previous_reading=prev, current_reading=curr, units_consumed=consumed, unit_rate=rate, amount=amt
            )

    print("Generating Bills & Payments...")
    payment_modes = ["cash", "upi"]
    for month in billing_months:
        for a in all_assignments:
            if a.rent_start_date <= datetime.date(month.year, month.month, 28):
                elec_amt = Decimal("0.00")
                if a.rental_unit.room:
                    r_id = a.rental_unit.room.id
                    reading = ElectricityReading.objects.filter(room_id=r_id, reading_month=month).first()
                    if reading:
                        sharing_count = TenantAssignment.objects.filter(
                            rental_unit__room_id=r_id, status="active", rent_start_date__lte=datetime.date(month.year, month.month, 28)
                        ).count()
                        sharing_count = max(1, sharing_count)
                        elec_amt = Decimal(str(reading.amount)) / Decimal(str(sharing_count))
                else:
                    elec_amt = Decimal("500.00")

                rent_amt = a.final_rent
                total_amt = rent_amt + elec_amt
                
                is_july = (month.month == 7 and month.year == 2026)
                status = "pending" if is_july else "paid"
                due = datetime.date(month.year, month.month, 10)

                bill = Bill.objects.create(
                    assignment=a, bill_month=month, rent_amount=rent_amt, electricity_amount=elec_amt,
                    additional_amount=Decimal("0.00"), total_amount=total_amt, due_date=due, status=status
                )

                if status == "paid":
                    mode = payment_modes[hash(str(a.id)) % 2]
                    Payment.objects.create(
                        bill=bill, amount_paid=total_amt, payment_mode=mode,
                        paid_at=datetime.datetime(month.year, month.month, 5, 10, 0),
                        utr_number=f"UTR{month.year}{month.month:02d}{hash(str(a.id)) % 100000:05d}" if mode == "upi" else ""
                    )

    print("Syncing rental unit statuses...")
    from rent.views import update_rental_unit_status
    for ru in RentalUnit.objects.all():
        update_rental_unit_status(ru)

    print("Database seeding of Building 1 & 2 completed successfully!")

if __name__ == "__main__":
    seed_all()
