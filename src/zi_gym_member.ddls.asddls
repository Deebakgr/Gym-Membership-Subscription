@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Gym Member Interface View'
define root view entity ZI_GYM_MEMBER
  as select from zgym_member_t
{
  key member_id            as MemberId,
      member_name          as MemberName,
      email                as Email,
      phone                as Phone,
      plan_type            as PlanType,
      
      /* --- Calculate Criticality HERE in the base view --- */
      case plan_type
        when 'VIP'     then 3
        when 'PREMIUM' then 2
        when 'BASIC'   then 5
        else 0
      end as PlanCriticality,
      
      start_date           as StartDate,
      end_date             as EndDate,
      status               as Status,
      
       /* --- ADD THIS CASE STATEMENT FOR COLOR --- */
      /* 3 = Green, 1 = Red, 2 = Yellow, 0 = Grey */
      case status
        when 'ACTIVE'    then 3 
        when 'CANCELLED' then 1
        when 'PENDING'   then 2
        else 0
      end                  as StatusCriticality,
 
      monthly_fee          as MonthlyFee,
      currency_code        as CurrencyCode,

      @Semantics.user.createdBy: true
      created_by           as CreatedBy, 
      @Semantics.systemDateTime.createdAt: true
      created_at           as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by      as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at      as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
