"""
URL configuration for core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from rent import views


urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/login/', views.login_user, name='login_user'),
    path("api/dashboard/",views.dashboard,name="dashboard"),
    path("api/buildings/", views.buildings_list),
    path("api/buildings/<uuid:id>/", views.building_detail),
    path("api/buildings-dropdown/", views.buildings_dropdown),
    path("api/floors-by-building/<uuid:building_id>/",views.floors_by_building),
    path("api/flats/", views.flats_list),
    path("api/flat/<uuid:flat_id>/",views.flat_detail),
    path("api/add-flat/",views.create_flat),
    path("api/update-flat/<uuid:flat_id>/",views.update_flat),
    path("api/delete-flat/<uuid:flat_id>/",views.delete_flat),
    path("api/flats-by-floor/<uuid:floor_id>/",views.flats_by_floor),
    path("api/rooms/", views.rooms_list),
    path("api/add-room/", views.create_room),
    path("api/update-room/<uuid:room_id>/", views.update_room),
    path("api/delete-room/<uuid:room_id>/", views.delete_room),
    path("api/rooms-by-flat/<uuid:flat_id>/",views.rooms_by_flat),
    path("api/tenant-assignments/",views.tenant_assignments_list,name="tenant_assignments_list",),
    path("api/add-tenant-assignment/",views.add_tenant_assignment,name="add_tenant_assignment",),
    path("api/update-tenant-assignment/<uuid:assignment_id>/",views.update_tenant_assignment,name="update_tenant_assignment",),
    path("api/vacate-tenant/<uuid:assignment_id>/",views.vacate_tenant,name="vacate_tenant",),
    path("api/delete-assignment/<uuid:assignment_id>/", views.delete_assignment),
    path("api/assignments/report/pdf/", views.assignments_report_view),
    path("api/tenants-dropdown/",views.tenants_dropdown,name="tenants_dropdown",),
    path("api/rental-units-dropdown/",views.rental_units_dropdown,name="rental_units_dropdown",),
    path("api/rental-units/",views.rental_units_list),
    path("api/rental-units/create/",views.create_rental_unit),
    path("api/rental-units/<uuid:rental_unit_id>/update/",views.update_rental_unit),
    path("api/rental-units/<uuid:rental_unit_id>/delete/",views.delete_rental_unit),
    path("api/tenants/", views.tenants_list),
    path("api/create-tenant/", views.create_tenant),
    path("api/tenants/<uuid:tenant_id>/", views.tenant_detail),
    path("api/update-tenant/<uuid:tenant_id>/", views.update_tenant),
    path("api/delete-tenant/<uuid:tenant_id>/", views.delete_tenant),
    path("api/tenants/<uuid:tenant_id>/profile/", views.tenant_profile),
    path("api/electricity-readings/", views.electricity_readings_list),
    path("api/electricity/report/pdf/", views.electricity_report_view),
    path("api/create-electricity-reading/", views.create_electricity_reading),
    path("api/electricity/<uuid:reading_id>/update/", views.update_electricity_reading),
    path("api/electricity/<uuid:reading_id>/delete/", views.delete_electricity_reading),
    path("api/electricity/room/<uuid:room_id>/", views.electricity_by_room),
    path("api/bills/", views.bills_list),
    path("api/bills/report/pdf/", views.bills_report_view),
    path("api/bills/create/", views.create_bill),
    path("api/bills/<uuid:bill_id>/update/", views.update_bill),
    path("api/bills/<uuid:bill_id>/delete/", views.delete_bill),
    path("api/charges/", views.additional_charges_list),
    path("api/charges/create/", views.create_additional_charge),
    path("api/charges/<uuid:charge_id>/delete/", views.delete_additional_charge),
    path("api/payments/create/", views.create_payment),
    path("api/payments/<uuid:payment_id>/delete/", views.delete_payment),
    path("api/payments/transactions/", views.payment_transactions_list),
    path("api/payments/transactions/create/", views.create_payment_transaction),
    path("api/complaints/", views.complaints_list),
    path("api/complaints/create/", views.create_complaint),
    path("api/complaints/<uuid:complaint_id>/update/", views.update_complaint),
    path("api/complaints/<uuid:complaint_id>/delete/", views.delete_complaint),
    path("api/maintenance/", views.maintenance_requests_list),
    path("api/maintenance/create/", views.create_maintenance_request),
    path("api/maintenance/<uuid:request_id>/update/", views.update_maintenance_request),
    path("api/documents/", views.documents_list),
    path("api/documents/<uuid:document_id>/", views.document_detail),
    path("api/documents/create/", views.create_document),
    path("api/documents/<uuid:document_id>/update/", views.update_document),
    path("api/documents/<uuid:document_id>/delete/", views.delete_document),
    path("api/vacate/create/", views.create_vacate_notice),
    path("api/vacate/list/", views.list_vacate_notices),
    path("api/vacate/<uuid:notice_id>/approve/", views.approve_vacate_notice),
    path("api/vacate/<uuid:notice_id>/reject/", views.reject_vacate_notice),
    path("api/vacate/<uuid:notice_id>/complete/", views.complete_vacate_notice),
    path("api/notifications/create/", views.create_notification),
    path("api/notifications/bulk/", views.create_bulk_notifications),
    path("api/notifications/", views.list_notifications),
    path("api/notifications/<uuid:notification_id>/read/", views.mark_as_read),
    path("api/notifications/<uuid:notification_id>/unread/", views.mark_as_unread),
    path("api/notifications/<uuid:notification_id>/delete/", views.delete_notification),
    path("api/settings/", views.get_settings),
    path("api/settings/update/", views.update_settings),
    path("api/profile/", views.profile_view),
    path("api/managers/",views.managers_api,)
]
