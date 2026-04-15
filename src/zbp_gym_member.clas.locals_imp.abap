CLASS lhc_GymMember DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_instance_authorizations FOR INSTANCE AUTHORIZATION
        IMPORTING keys REQUEST requested_authorizations FOR GymMember RESULT result,

      " Added the missing Numbering method
      earlynumbering_create FOR NUMBERING
        IMPORTING entities FOR CREATE GymMember,

      validateMember FOR VALIDATE ON SAVE
        IMPORTING keys FOR GymMember~validateMember,

      validateDates FOR VALIDATE ON SAVE
        IMPORTING keys FOR GymMember~validateDates,

      validatePlan FOR VALIDATE ON SAVE
        IMPORTING keys FOR GymMember~validatePlan,

      setDefaultStatus FOR DETERMINE ON MODIFY
        IMPORTING keys FOR GymMember~setDefaultStatus,

      computeEndDate FOR DETERMINE ON MODIFY
        IMPORTING keys FOR GymMember~computeEndDate,

      ActivateMembership FOR MODIFY
        IMPORTING keys FOR ACTION GymMember~ActivateMembership RESULT result,

      CancelMembership FOR MODIFY
        IMPORTING keys FOR ACTION GymMember~CancelMembership RESULT result,

      RenewMembership FOR MODIFY
        IMPORTING keys FOR ACTION GymMember~RenewMembership RESULT result,
      get_global_authorizations FOR GLOBAL AUTHORIZATION
            IMPORTING REQUEST requested_authorizations FOR GymMember RESULT result.
ENDCLASS.

CLASS lhc_GymMember IMPLEMENTATION.

  "-- INSTANCE AUTHORIZATION
  METHOD get_instance_authorizations.
  ENDMETHOD.

METHOD earlynumbering_create.
  DATA: lv_max_id TYPE i.

  " 1. Find the highest existing Member ID in the database table
  SELECT SINGLE FROM zgym_member_t
    FIELDS MAX( member_id )
    INTO @DATA(lv_current_max).

  " 2. Safely convert: if table is empty, MAX returns initial/null → default to 0
  IF lv_current_max IS INITIAL.
    lv_max_id = 0.
  ELSE.
    TRY.
        lv_max_id = CONV i( lv_current_max ).
      CATCH cx_sy_conversion_no_number.
        lv_max_id = 0. " Fallback if conversion still fails
    ENDTRY.
  ENDIF.

  " 3. Loop through the records being created and assign the next ID (+1)
  LOOP AT entities INTO DATA(ls_entity).

    lv_max_id += 1.

    APPEND VALUE #( %cid     = ls_entity-%cid
                    MemberId = CONV #( lv_max_id ) ) TO mapped-gymmember.

  ENDLOOP.
ENDMETHOD.

  "-- VALIDATION: Member fields
  METHOD validateMember.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( MemberName Email Phone )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

    LOOP AT lt_members INTO DATA(ls_member).

      " Validate MemberName
      IF ls_member-MemberName IS INITIAL.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky     = ls_member-%tky
          %msg     = new_message( id       = '00'
                                  number   = '000'
                                  severity = if_abap_behv_message=>severity-error
                                  v1       = 'Member Name is mandatory' )
          %element-MemberName = if_abap_behv=>mk-on
        ) TO reported-GymMember.
      ENDIF.

      " Validate Email format (basic check)
      IF ls_member-Email IS NOT INITIAL AND NOT ls_member-Email CA '@'.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky     = ls_member-%tky
          %msg     = new_message( id       = '00'
                                  number   = '000'
                                  severity = if_abap_behv_message=>severity-error
                                  v1       = 'Email address must contain @' )
          %element-Email = if_abap_behv=>mk-on
        ) TO reported-GymMember.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  "-- VALIDATION: Date logic
  METHOD validateDates.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( StartDate EndDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    LOOP AT lt_members INTO DATA(ls_member).

      IF ls_member-StartDate IS INITIAL.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky  = ls_member-%tky
          %msg  = new_message( id       = '00'
                               number   = '000'
                               severity = if_abap_behv_message=>severity-error
                               v1       = 'Start Date is mandatory' )
          %element-StartDate = if_abap_behv=>mk-on
        ) TO reported-GymMember.

      ELSEIF ls_member-EndDate IS NOT INITIAL AND ls_member-EndDate <= ls_member-StartDate.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky  = ls_member-%tky
          %msg  = new_message( id       = '00'
                               number   = '000'
                               severity = if_abap_behv_message=>severity-error
                               v1       = 'End Date must be after Start Date' )
          %element-EndDate = if_abap_behv=>mk-on
        ) TO reported-GymMember.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  "-- VALIDATION: Plan type
  METHOD validatePlan.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( PlanType MonthlyFee )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    LOOP AT lt_members INTO DATA(ls_member).
      " Fixed the Selection Table error by using a direct IF statement
      IF ls_member-PlanType <> 'BASIC' AND ls_member-PlanType <> 'PREMIUM' AND ls_member-PlanType <> 'VIP'.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky  = ls_member-%tky
          %msg  = new_message( id       = '00'
                               number   = '000'
                               severity = if_abap_behv_message=>severity-error
                               v1       = 'Plan must be BASIC, PREMIUM or VIP' )
          %element-PlanType = if_abap_behv=>mk-on
        ) TO reported-GymMember.
      ENDIF.

      IF ls_member-MonthlyFee <= 0.
        " Removed %state_area
        APPEND VALUE #( %tky = ls_member-%tky ) TO failed-GymMember.

        APPEND VALUE #(
          %tky  = ls_member-%tky
          %msg  = new_message( id       = '00'
                               number   = '000'
                               severity = if_abap_behv_message=>severity-error
                               v1       = 'Monthly Fee must be greater than zero' )
          %element-MonthlyFee = if_abap_behv=>mk-on
        ) TO reported-GymMember.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  "-- DETERMINATION: Set default status and currency on create
  METHOD setDefaultStatus.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( Status CurrencyCode )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_GYM_MEMBER\\GymMember.

    LOOP AT lt_members INTO DATA(ls_member).
      " Set Status to ACTIVE and Currency to USD automatically if they are blank
      APPEND VALUE #(
        %tky         = ls_member-%tky
        Status       = COND #( WHEN ls_member-Status IS INITIAL THEN 'ACTIVE' ELSE ls_member-Status )
        CurrencyCode = COND #( WHEN ls_member-CurrencyCode IS INITIAL THEN 'USD' ELSE ls_member-CurrencyCode )
        %control-Status       = if_abap_behv=>mk-on
        %control-CurrencyCode = if_abap_behv=>mk-on
      ) TO lt_update.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        UPDATE FIELDS ( Status CurrencyCode )
        WITH lt_update
      REPORTED DATA(lt_rep).

    reported = CORRESPONDING #( DEEP lt_rep ).
  ENDMETHOD.

 "-- DETERMINATION: Compute EndDate from StartDate + plan duration
  METHOD computeEndDate.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( StartDate PlanType )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_GYM_MEMBER\\GymMember.

    LOOP AT lt_members INTO DATA(ls_member).
      IF ls_member-StartDate IS INITIAL. CONTINUE. ENDIF.

      DATA(lv_months) = SWITCH #( ls_member-PlanType
        WHEN 'BASIC'   THEN 1
        WHEN 'PREMIUM' THEN 6
        WHEN 'VIP'     THEN 12
        ELSE                1 ).

      " Cloud-Compliant Date Math
      DATA(lv_year)  = CONV i( ls_member-StartDate(4) ).
      DATA(lv_month) = CONV i( ls_member-StartDate+4(2) ).
      DATA(lv_day)   = CONV i( ls_member-StartDate+6(2) ).

      lv_month = lv_month + lv_months.

      " Roll over years if months exceed 12
      WHILE lv_month > 12.
        lv_month = lv_month - 12.
        lv_year = lv_year + 1.
      ENDWHILE.

      " Handle End-of-Month overflows (e.g., Jan 31 + 1 month = Feb 28/29)
      IF lv_day > 28.
        CASE lv_month.
          WHEN 2.
            " Leap year check
            IF ( lv_year MOD 4 = 0 AND lv_year MOD 100 <> 0 ) OR ( lv_year MOD 400 = 0 ).
              lv_day = 29.
            ELSE.
              lv_day = 28.
            ENDIF.
          WHEN 4 OR 6 OR 9 OR 11.
            IF lv_day > 30.
              lv_day = 30.
            ENDIF.
        ENDCASE.
      ENDIF.

      " Reconstruct the Date String
      DATA(lv_year_str)  = CONV numc4( lv_year ).
      DATA(lv_month_str) = CONV numc2( lv_month ).
      DATA(lv_day_str)   = CONV numc2( lv_day ).

      DATA(lv_end_date) = CONV d( lv_year_str && lv_month_str && lv_day_str ).

      APPEND VALUE #(
        %tky    = ls_member-%tky
        EndDate = lv_end_date
        %control-EndDate = if_abap_behv=>mk-on
      ) TO lt_update.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        UPDATE FIELDS ( EndDate )
        WITH lt_update
      REPORTED DATA(lt_rep).

    reported = CORRESPONDING #( DEEP lt_rep ).
  ENDMETHOD.

  "-- ACTION: Activate Membership
  METHOD ActivateMembership.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_GYM_MEMBER\\GymMember.

    LOOP AT lt_members INTO DATA(ls_member).
      IF ls_member-Status = 'CANCELLED' OR ls_member-Status = 'EXPIRED'.
        APPEND VALUE #(
          %tky   = ls_member-%tky
          Status = 'ACTIVE'
          %control-Status = if_abap_behv=>mk-on
        ) TO lt_update.
      ELSE.
        APPEND VALUE #(
          %tky = ls_member-%tky
          %msg = new_message( id       = '00'
                              number   = '000'
                              severity = if_abap_behv_message=>severity-warning
                              v1       = 'Membership is already active' )
        ) TO reported-GymMember.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        UPDATE FIELDS ( Status )
        WITH lt_update
      REPORTED DATA(lt_rep).

    " Return updated records
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls IN lt_result (
        %tky   = ls-%tky
        %param = ls
      )
    ).
  ENDMETHOD.

  "-- ACTION: Cancel Membership
  METHOD CancelMembership.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        FIELDS ( Status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_GYM_MEMBER\\GymMember.

    LOOP AT lt_members INTO DATA(ls_member).
      IF ls_member-Status <> 'CANCELLED'.
        APPEND VALUE #(
          %tky   = ls_member-%tky
          Status = 'CANCELLED'
          %control-Status = if_abap_behv=>mk-on
        ) TO lt_update.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        UPDATE FIELDS ( Status )
        WITH lt_update
      REPORTED DATA(lt_rep).

    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls IN lt_result (
        %tky   = ls-%tky
        %param = ls
      )
    ).
  ENDMETHOD.

  "-- ACTION: Renew Membership
  METHOD RenewMembership.
    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_members).

    DATA lt_update TYPE TABLE FOR UPDATE ZI_GYM_MEMBER\\GymMember.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_members INTO DATA(ls_member).
      DATA(lv_months) = keys[ KEY entity %key = ls_member-%key ]-%param-RenewalMonths.
      IF lv_months <= 0. lv_months = 1. ENDIF.

      " New end date = max(today, current end_date) + months
      DATA(lv_base_date) = COND #(
        WHEN ls_member-EndDate >= lv_today
        THEN ls_member-EndDate
        ELSE lv_today
      ).

      " Cloud-Compliant Date Math
      DATA(lv_year)  = CONV i( lv_base_date(4) ).
      DATA(lv_month) = CONV i( lv_base_date+4(2) ).
      DATA(lv_day)   = CONV i( lv_base_date+6(2) ).

      lv_month = lv_month + lv_months.

      WHILE lv_month > 12.
        lv_month = lv_month - 12.
        lv_year = lv_year + 1.
      ENDWHILE.

      IF lv_day > 28.
        CASE lv_month.
          WHEN 2.
            IF ( lv_year MOD 4 = 0 AND lv_year MOD 100 <> 0 ) OR ( lv_year MOD 400 = 0 ).
              lv_day = 29.
            ELSE.
              lv_day = 28.
            ENDIF.
          WHEN 4 OR 6 OR 9 OR 11.
            IF lv_day > 30.
              lv_day = 30.
            ENDIF.
        ENDCASE.
      ENDIF.

      DATA(lv_year_str)  = CONV numc4( lv_year ).
      DATA(lv_month_str) = CONV numc2( lv_month ).
      DATA(lv_day_str)   = CONV numc2( lv_day ).

      DATA(lv_new_end) = CONV d( lv_year_str && lv_month_str && lv_day_str ).

      APPEND VALUE #(
        %tky    = ls_member-%tky
        EndDate = lv_new_end
        Status  = 'ACTIVE'
        %control-EndDate = if_abap_behv=>mk-on
        %control-Status  = if_abap_behv=>mk-on
      ) TO lt_update.
    ENDLOOP.

    MODIFY ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        UPDATE FIELDS ( EndDate Status )
        WITH lt_update
      REPORTED DATA(lt_rep).

    READ ENTITIES OF ZI_GYM_MEMBER IN LOCAL MODE
      ENTITY GymMember
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    result = VALUE #(
      FOR ls IN lt_result (
        %tky   = ls-%tky
        %param = ls
      )
    ).
  ENDMETHOD.

  METHOD get_global_authorizations.

    " Allow Create
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

    " Allow Update
    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.

    " Allow Delete
    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
