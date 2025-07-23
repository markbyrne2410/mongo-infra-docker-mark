# Authentik Configuration Steps

This document outlines the steps to configure a basic SAML integration in Authentik with Ops Manager. The following steps were performed and verified as working with Ops Manager `8.0.6`. 

---

## 1. Create a User

Navigate to: **Directory → Users → Create**

- **Username:** `<your-username>`
- **User Type:** `Internal`
- **Email:** `<your-email>`
- **Active:** Ensure `is_active` is enabled
- **Path:** Keep as `users`
![create_user](/authentik/docs/images/create_user.png)

### Set Password
Navigate to: **Users → [User] → Set Password**
![set_password](/authentik/docs/images/set_password.png)

---

## 2. Create a Role

Navigate to: **Directory → Roles → Create**

Create a role with your preferred name.
![create_role](/authentik/docs/images/create_role.png)
---

## 3. Create a Group

Navigate to: **Directory → Groups → Create**

- Add the role created in step 2 to the **Selected Roles** section.
![create_group](/authentik/docs/images/create_group.png)
---

## 4. Add User to Group

Navigate to: **Directory → Groups → [Your Group] → Users Tab**

- Select **Add existing user** and select the user created in Step 1.
![add_user_to_group](/authentik/docs/images/add_user_to_group.png)
---

## 5. Create User Attributes (Property Mappings)

Navigate to: **Customization → Property Mappings → Create → SAML Provider Property Mapping**

Create the following mappings:

### Mapping: `fname`
![mapping_fname](/authentik/docs/images/fname.png)
```python
return user.attributes.get("first_name") or user.name.split(" ")[0]
```
### Mapping: `lname`
![mapping_lname](/authentik/docs/images/lname.png)
```python
return user.attributes.get("last_name") or user.name.split(" ")[-1]
```
### Mapping: `email`
![mapping_email](/authentik/docs/images/email.png)
```python
return request.user.email
```
### Mapping: `groups`
![mapping_group](/authentik/docs/images/groups.png)
```python
return [group.name for group in user.groups.all()]
```

## 6. Create a SAML Provider

Navigate to **Applications -> Providers -> Create -> SAML Provider**
- The SAML Provider config should match the following screenshot
- Note within section SAML mappings, add the below from **Available User Property Mappings** to **Selected User Property Mappings**
`fname`, `lname`, `email`, `groups`

![new_provider_1](/authentik/docs/images/new_provider_1.png)

![new_provider_2](/authentik/docs/images/new_provider_2.png)

![new_provider_3](/authentik/docs/images/new_provider_3.png)


## 7. Create an Application for the Service Provider

Navigate to **Applications -> Applications -> Create -> Choose SAML Provider**

- Create an Application as follows

![create_application](/authentik/docs/images/create_application.png)


## 8. Configure Ops Manager for SAML

Add the below details in Ops manager user authentication page which can all be found in your created Provider in Authentik(**Navigate Applications->Providers->choose Service Provider**):
 - `Identity provided URL:`  Field `EntityID/Isssuer`
 - `SSO EndPoint URL:` -> choose the `SSO URL(IdP-initiated Login)` URL from your Authentik Service Provider. Choosing the `SSO URL (Post)` caused errors in testing of this. 
 - `SLO EndPoint URL:` -> choose the `SLO URL (Redirect)` URL from your Authentik Service Provider. Choosing `SLO URL (Post)` caused errors during testing.
 - `Identity Provider X509 Certificate:` retrieve via the `Download signing certificate` Download button

![om_config_1](/authentik/docs/images/om_config_1.png)

![om_config_2](/authentik/docs/images/om_config_2.png)

![om_config_3](/authentik/docs/images/om_config_3.png)

![om_config_4](/authentik/docs/images/om_config_4.png)