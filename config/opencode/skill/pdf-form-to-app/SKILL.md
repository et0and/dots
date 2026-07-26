---
name: pdf-form-to-app
description: >
  Convert a PDF or paper form into a fully wired multi-step Tutuki web form with backend job processing
  and email notifications. Use this skill when: 
  (1) Creating a new online form from a PDF document,
  (2) Building a new service form for a business unit, 
  (3) Converting a government/council form into the Tutuki forms system, 
  (4) Adding a form with submission processing and email confirmations.
  Triggers: new form, convert this PDF, add a form for [business unit], create form from PDF.
---

# PDF Form to Tutuki App

Convert a PDF/paper form into a fully functional multi-step web form with backend job processing and email notifications.

## Workflow Overview

```
PDF source → Markdown extraction → Form config + Steps + Strings
                                  → Job class + Job registry wiring
                                  → Email templates + Comms registry wiring
                                  → API route wiring
```

IMPORTANT: If a PDF URL or file is not provided by the user, prompt them to provide this before proceeding.

## Phase 0: Extract Form Content to Markdown

Before writing any code, convert the source PDF into a structured Markdown document the coder agent can work from.

### Remote PDF (URL available, provided by user)

Fetch via Jina Reader to get a clean Markdown extraction:

```
r.jina.ai/https://example.com/path/to/form.pdf
```

Use WebFetch or cURL to retrieve the result. Save the output to a temporary working file (e.g. `.github/skills/pdf-form-to-app/scratch/extracted-form.md`) for reference during implementation.

### Local PDF (file on disk)

Use the Read tool to view the PDF visually (multimodal vision). Then manually create a structured Markdown file capturing:

- Form title and description
- All sections/steps and their fields
- Field types (text, date, radio, checkbox, file upload, etc.)
- Validation rules (required, patterns, max lengths)
- Conditional logic (fields that appear based on other answers)
- Any declarations, checklists, or consent sections

### Markdown Structure Target

```markdown
# Form Title

## Section 1: [Section Name]

- **Field Name** (type: text, required): Description/help text
- **Field Name** (type: radio, required): Option A | Option B | Option C
- **Field Name** (type: fileupload): Accepted types, max size

## Section 2: [Section Name]

...

## Declaration

- [ ] Consent text here
```

## Phase 1: Frontend — Form Configuration

### Directory Structure

Create under `apps/web/features/forms/configs/{business-unit}/{form-id}/`:

```
{form-id}/
├── form.ts          # FormConfig export
├── steps.ts         # Step[] array
├── forms/
│   ├── step1.tsx    # FieldConfig[] for each step
│   ├── step2.tsx
│   ├── ...
│   └── summary.tsx  # Always the final step
└── strings.ts       # All i18n strings (StringsDict)
```

Also add a hero SVG at `apps/web/public/images/hero/{form-name}.svg`.

### form.ts Pattern

```typescript
import { FormConfig } from '@wcc/forms';
import { myDict } from './strings';

export const formConfig: FormConfig = {
  formId: '{form-id}',
  title: myDict.t('service.formId.title'),
  teReoTitle: myDict.t('service.formId.teReoTitle'),
  description: myDict.t('service.formId.description'),
  exitLink: 'https://wellington.govt.nz/relevant-page',
  illustrationPath: '/images/hero/{form-name}.svg',
  saveProgress: true,
  helpfulInfo: [
    {
      title: myDict.t('service.formId.helpfulInfo.title'),
      content: myDict.t('service.formId.helpfulInfo.content'),
    },
  ],
  confirmationContent: myDict.t('service.formId.confirmationContent'),
  steps: [], // Populated at runtime from steps.ts
};
```

### steps.ts Pattern

```typescript
import { Step } from '@wcc/forms';
import applicantDetails from './forms/applicantDetails';
import summary from './forms/summary';

const steps: Step[] = [
  {
    title: 'Applicant details',
    slug: 'applicant-details',
    id: 'applicantDetails',
    summarize: false,
    fields: applicantDetails,
  },
  // ... more steps
  {
    title: 'Review and submit',
    slug: 'summary',
    id: 'summary',
    summarize: true,
    fields: summary,
  },
];

export default steps;
```

### Field Definitions (forms/\*.tsx)

Each step file exports a `FieldConfig[]`. Key field types:

| Type                                       | Notes                                          |
| ------------------------------------------ | ---------------------------------------------- |
| `text`, `email`, `tel`, `date`, `textarea` | Standard inputs                                |
| `radio`, `checkbox`                        | With `options` array                           |
| `address`                                  | Optional `wellingtonOnly` restriction          |
| `fileupload`                               | `types`, `maxFiles`, `maxFileSize` (MB)        |
| `content`                                  | Static HTML/React content (declarations, info) |
| `hidden`                                   | Auto-populated (e.g. `declarationDate`)        |
| `conditional`                              | Shows fields based on other field values       |
| `divider`, `summary`                       | Layout elements                                |

Validation uses Yup via the `rules` property:

```typescript
{
  type: 'text',
  id: 'fullLegalName',
  name: 'fullLegalName',
  label: myDict.t('...label'),
  rules: {
    required: { value: true, message: myDict.t('...required') },
  },
}
```

### strings.ts Pattern

All user-facing text uses i18n. Create a `StringsDict` with nested keys:

```typescript
import { StringsDict } from '@wcc/forms';

export const myDict = new StringsDict({
  service: {
    formId: {
      title: 'Form Title',
      forms: {
        applicantDetails: {
          fullLegalName: {
            label: 'Full legal name',
            required: 'Full legal name is required',
          },
        },
      },
    },
  },
});
```

All text must be written in **NZ English**.

## Phase 2: Backend — Job Processing

### Job Class

Create at `apps/api/src/services/TutukiJobs/jobs/{business-unit}/{JobName}.ts`:

```typescript
import { TutukiJob } from '../../TutukiJob';
import { dispatchCommunication } from '../../communications/dispatchCommunication';
import { getExpressLogger } from '@wcc/logger';

const logger = getExpressLogger('wcc:tutuki-apps:api:jobs:{business-unit}:{job-name}');

interface JobArgs {
  submissionId: string;
}

export class MyFormJob extends TutukiJob<JobArgs> {
  action = 'PROCESS_MY_FORM';
  protected retrySettings = null;

  async perform(args: JobArgs): Promise<void> {
    // 1. Fetch submission
    const submission = await formSubmissionRepository.get(args.submissionId);
    const payload = submission.payload as MyFormPayload;

    // 2. Generate signed URLs for any file uploads (24hr expiry)
    // 3. Dispatch confirmation email to applicant
    await dispatchCommunication('MyFormCopy', { to: payload.email, ...data });
    // 4. Dispatch notification email to internal team
    await dispatchCommunication('MyFormNotification', { to: internalEmail, ...data });
  }
}
```

### Wiring: Job Registry

Edit `apps/api/src/services/TutukiJobs/jobRegistry.ts`:

```typescript
import { MyFormJob } from './jobs/{business-unit}/MyFormJob';

export const jobRegistry: Record<string, unknown> = {
  // ... existing jobs
  MyFormJob,
};
```

### Wiring: Form ID → Job Mapping

Edit `apps/api/src/services/formSubmission/job.ts`:

```typescript
const FORM_ID_TO_JOB_NAMES: Readonly<Record<string, string>> = {
  // ... existing mappings
  '{form-id}': 'MyFormJob',
};
```

## Phase 3: Email Notifications

Each form typically needs two emails:

1. **Copy** — sent to the applicant as confirmation
2. **Notification** — sent to the internal team for processing

### Handlebars Templates

Create at `libs/@wcc/email/src/templates/{form_name}_{email_type}.hbs`:

```handlebars
{{#>main}}
<table>
  <tr><td>
    <p>Kia ora {{fullLegalName}},</p>
    <p>Thank you for your submission.</p>
    <p><strong>Application ID</strong><br />{{submissionId}}</p>
    <!-- Field summary table -->
    {{#if fileUploads}}
      <p><strong>Uploaded files</strong></p>
      {{#each fileUploads}}
        <a href='{{url}}'>{{fileName}}</a><br />
      {{/each}}
    {{/if}}
  </td></tr>
</table>
{{/main}}
```

### Wiring: Email Template Enum

Edit `libs/@wcc/email/src/types.ts`:

```typescript
export enum EmailTemplate {
  // ... existing
  MY_FORM_COPY = 'my_form_copy',
  MY_FORM_NOTIFICATION = 'my_form_notification',
}
```

### Wiring: Template Map

Edit `libs/@wcc/email/src/lib/email.ts` — import the compiled template and add to `templateMap`.

### Wiring: Communications Registry

Edit `apps/api/src/services/communications/communicationsRegistry.ts`:

```typescript
MyFormCopy: {
  kind: CommunicationType.EMAIL,
  template: EmailTemplate.MY_FORM_COPY,
  subject: 'Copy of your application - {{fullLegalName}}',
  from: fromAddress,
},
MyFormNotification: {
  kind: CommunicationType.EMAIL,
  template: EmailTemplate.MY_FORM_NOTIFICATION,
  subject: 'New application - {{fullLegalName}}',
  from: fromAddress,
},
```

### Wiring: Email Config Map

Edit `apps/api/src/services/communications/email.ts` — add entries to `emailConfigMap`.

## Checklist

### Frontend

- [ ] `form.ts` with FormConfig export
- [ ] `steps.ts` with Step[] default export
- [ ] Field definition files for each step in `forms/`
- [ ] `summary.tsx` as the final step
- [ ] `strings.ts` with all i18n text in NZ English
- [ ] Hero SVG image

### Backend

- [ ] Job class extending `TutukiJob`
- [ ] Job registered in `jobRegistry.ts`
- [ ] Form ID mapped in `formSubmission/job.ts`

### Email

- [ ] Handlebars template for applicant copy
- [ ] Handlebars template for internal notification
- [ ] `EmailTemplate` enum entries added
- [ ] Templates imported and added to `templateMap`
- [ ] Communications registered in `communicationsRegistry.ts`
- [ ] Email config entries in `email.ts`

### Logging

- [ ] Logger name follows pattern: `wcc:tutuki-apps:api:jobs:{business-unit}:{job-name}`
- [ ] Errors logged with `{ err }` field (not `error`)

## Anti-Patterns

- **Hardcoded strings** — All user-facing text must go through `StringsDict`
- **Missing validation** — Every required field on the PDF must have a `rules.required` entry
- **Skipping summary step** — Every form needs a final summary/review step
- **Generic email subjects** — Include identifying info like `{{fullLegalName}}` in subjects
- **Forgetting signed URLs** — File uploads need S3 signed URLs (24hr expiry) in email templates

## Reference Examples

Read these files for concrete, working implementations:

| Pattern           | Reference File                                                                                |
| ----------------- | --------------------------------------------------------------------------------------------- |
| Form config       | `apps/web/features/forms/configs/alcohol/new-managers-certificate/form.ts`                    |
| Steps             | `apps/web/features/forms/configs/alcohol/new-managers-certificate/steps.ts`                   |
| Field definitions | `apps/web/features/forms/configs/alcohol/new-managers-certificate/forms/applicantDetails.tsx` |
| Strings           | `apps/web/features/forms/configs/alcohol/strings.ts`                                          |
| Job class         | `apps/api/src/services/TutukiJobs/jobs/alcohol/AlcoholManagersCertificateApplicationJob.ts`   |
| Email template    | `libs/@wcc/email/src/templates/alcohol_managers_certificate_application_copy.hbs`             |

