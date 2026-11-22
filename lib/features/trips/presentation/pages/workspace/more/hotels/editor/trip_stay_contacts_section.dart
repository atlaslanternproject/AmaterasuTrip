// Sezione "Contatti" dell'editor: telefono, email e sito dell'alloggio,
// tutti facoltativi e modificabili. Telefono e sito si compilano da soli
// quando si sceglie il luogo con la ricerca Google (l'email no).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_validator.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_draft.dart';
import 'trip_stay_editor_section.dart';

class TripStayContactsSection extends StatelessWidget {
  const TripStayContactsSection({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final TripStayDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? check(
      TextEditingController controller,
      bool Function(String) ok,
      String message,
    ) {
      final text = controller.text.trim();
      return text.isEmpty || ok(text) ? null : message;
    }

    return TripStayEditorSection(
      title: l10n.staysSectionContacts,
      icon: Icons.contact_phone_outlined,
      children: [
        TextField(
          key: const Key('stay-phone'),
          controller: draft.phone,
          keyboardType: TextInputType.phone,
          maxLength: TripStayValidator.phoneMax,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysPhone,
            errorText: check(
              draft.phone,
              TripStayValidator.isPhone,
              l10n.staysErrPhone,
            ),
            counterText: '',
          ),
        ),
        TextField(
          key: const Key('stay-email'),
          controller: draft.email,
          keyboardType: TextInputType.emailAddress,
          maxLength: TripStayValidator.emailMax,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysEmail,
            errorText: check(
              draft.email,
              TripStayValidator.isEmail,
              l10n.staysErrEmail,
            ),
            counterText: '',
          ),
        ),
        TextField(
          key: const Key('stay-property-url'),
          controller: draft.propertyUrl,
          keyboardType: TextInputType.url,
          maxLength: AmaterasuWebLink.maxLength,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: l10n.staysPropertyUrl,
            errorText: check(
              draft.propertyUrl,
              AmaterasuWebLink.isValid,
              l10n.staysErrLink,
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
