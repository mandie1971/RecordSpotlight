System.debug(
    'DoNotCall createable: ' +
    Contact.DoNotCall.getDescribe().isCreateable()
);

System.debug(
    'DoNotCall updateable: ' +
    Contact.DoNotCall.getDescribe().isUpdateable()
);

System.debug(
    'Email createable: ' +
    Contact.Email.getDescribe().isCreateable()
);

System.debug(
    'AccountId createable: ' +
    Contact.AccountId.getDescribe().isCreateable()
);