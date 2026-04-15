@EndUserText.label: 'Gym Member Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
define root view entity ZC_GYM_MEMBER
  provider contract transactional_query
  as projection on ZI_GYM_MEMBER
{
  key MemberId,
      MemberName, 
      Email,
      Phone,

      /* Value Help removed. Fiori will render this as a plain text input. */
      PlanType,
      
    PlanCriticality,

      StartDate,
      EndDate,

      /* Value Help removed. Fiori will render this as a plain text input. */
      Status,
      
      StatusCriticality,

      @Semantics.amount.currencyCode: 'CurrencyCode'
      MonthlyFee,

      @Semantics.currencyCode: true
      /* Add the Value Help to the CurrencyCode field here */
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Currency', element: 'Currency' } }]
      CurrencyCode,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
