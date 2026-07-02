import os
import django
import datetime
import random
from decimal import Decimal

# Setup django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rent.models import Users, Building, Floor, Flat, Room, RentalUnit, TenantAssignment, ElectricityReading, Bill, Payment

def update_and_seed():
    print("Updating tenant assignment start dates...")
    today = datetime.date.today()
    
    # Fetch active tenant assignments by name
    assignments = TenantAssignment.objects.filter(tenant__name__startswith="tenant", status="active")
    
    assignments_by_name = {a.tenant.name: a for a in assignments}
    
    # 1. Update start dates:
    # tenant1 & tenant2: July 1, 2026
    # tenant3: January 15, 2026
    # tenant4: February 1, 2026
    # tenant5: March 1, 2026
    # tenant6: March 15, 2026
    # tenant7: April 1, 2026
    
    dates_map = {
        "tenant1": datetime.date(2026, 7, 1),
        "tenant2": datetime.date(2026, 7, 1),
        "tenant3": datetime.date(2026, 1, 15),
        "tenant4": datetime.date(2026, 2, 1),
        "tenant5": datetime.date(2026, 3, 1),
        "tenant6": datetime.date(2026, 3, 15),
        "tenant7": datetime.date(2026, 4, 1),
    }
    
    for t_name, start_date in dates_map.items():
        if t_name in assignments_by_name:
            a = assignments_by_name[t_name]
            a.rent_start_date = start_date
            a.save()
            print(f"Updated {t_name} start date to {start_date}")

    # Delete existing bills & electricity readings for these assignments/rooms to start fresh
    print("Clearing existing Bills, Payments & Electricity Readings...")
    assigned_room_ids = [a.rental_unit.room.id for a in assignments if a.rental_unit.room]
    ElectricityReading.objects.filter(room_id__in=assigned_room_ids).delete()
    
    assignment_ids = [a.id for a in assignments]
    Bill.objects.filter(assignment_id__in=assignment_ids).delete()

    # Define billing months from Jan 2026 to July 2026
    billing_months = [
        datetime.date(2026, 1, 1),
        datetime.date(2026, 2, 1),
        datetime.date(2026, 3, 1),
        datetime.date(2026, 4, 1),
        datetime.date(2026, 5, 1),
        datetime.date(2026, 6, 1),
        datetime.date(2026, 7, 1),
    ]

    # 2. Generate Electricity Readings for rooms
    print("Generating Electricity Readings for rooms...")
    base_readings = {r_id: 1000 for r_id in assigned_room_ids}
    
    for month in billing_months:
        for r_id in assigned_room_ids:
            prev = base_readings[r_id]
            # Consume around 100-150 units
            consumed = 100 + (month.month * 5)
            curr = prev + consumed
            base_readings[r_id] = curr
            
            rate = Decimal("10.00")
            amt = Decimal(str(consumed)) * rate
            
            ElectricityReading.objects.create(
                room_id=r_id,
                reading_month=month,
                previous_reading=prev,
                current_reading=curr,
                units_consumed=consumed,
                unit_rate=rate,
                amount=amt
            )
            print(f"Created ElectricityReading for Room {r_id} month {month.strftime('%Y-%m')}: {consumed} units")

    # 3. Generate Bills and Payments
    print("Generating monthly bills and payments...")
    for month in billing_months:
        for a in assignments:
            # A bill is only generated if the tenant was active in that month
            t_start = a.rent_start_date
            if t_start <= datetime.date(month.year, month.month, 28): # Allow active if started before month end
                # Calculate electricity amount
                elec_amt = Decimal("0.00")
                if a.rental_unit.room:
                    r_id = a.rental_unit.room.id
                    reading = ElectricityReading.objects.filter(room_id=r_id, reading_month=month).first()
                    if reading:
                        # Shared room -> split electricity
                        sharing_count = TenantAssignment.objects.filter(
                            rental_unit__room_id=r_id,
                            status="active",
                            rent_start_date__lte=datetime.date(month.year, month.month, 28)
                        ).count()
                        sharing_count = max(1, sharing_count)
                        elec_amt = Decimal(str(reading.amount)) / Decimal(str(sharing_count))
                else:
                    # Flat -> flat utility fee of 500
                    elec_amt = Decimal("500.00")

                rent_amt = a.final_rent
                total_amt = rent_amt + elec_amt
                
                # July 2026 bill is pending, others are paid
                is_july = (month.month == 7 and month.year == 2026)
                status = "pending" if is_july else "paid"
                due = datetime.date(month.year, month.month, 10)

                bill = Bill.objects.create(
                    assignment=a,
                    bill_month=month,
                    rent_amount=rent_amt,
                    electricity_amount=elec_amt,
                    additional_amount=Decimal("0.00"),
                    total_amount=total_amt,
                    due_date=due,
                    status=status
                )
                print(f"Created Bill for {a.tenant.name} for {month.strftime('%Y-%m')}: Rs.{total_amt} ({status})")

                # If paid, generate a payment record
                if status == "paid":
                    Payment.objects.create(
                        bill=bill,
                        amount_paid=total_amt,
                        payment_mode=random_payment_mode(a.id),
                        paid_at=datetime.datetime(month.year, month.month, 5, 10, 0),
                        utr_number=f"UTR{month.year}{month.month:02d}{hash(a.id) % 100000:05d}"
                    )
                    print(f"Created Payment for {a.tenant.name} for {month.strftime('%Y-%m')}")

    print("Seeding of monthly bills and payments finished successfully!")

def random_payment_mode(seed_val):
    modes = ["cash", "upi", "bank", "card"]
    idx = hash(seed_val) % len(modes)
    return modes[idx]

if __name__ == "__main__":
    update_and_seed()
