import 'package:cpims_mobile/Models/case_load_model.dart';
import 'package:cpims_mobile/Models/statistic_model.dart';
import 'package:cpims_mobile/providers/ui_provider.dart';
import 'package:cpims_mobile/screens/cpara/model/detail_model.dart';
import 'package:cpims_mobile/screens/cpara/provider/cpara_provider.dart';
import 'package:cpims_mobile/screens/cpara/widgets/cpara_stable_widget.dart';
import 'package:cpims_mobile/screens/cpara/widgets/custom_radio_buttons.dart';
import 'package:cpims_mobile/screens/ovc_care/ovc_care_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/db_provider.dart';
import '../../registry/organisation_units/widgets/steps_wrapper.dart';

class CparaDetailsWidget extends StatefulWidget {
  const CparaDetailsWidget({super.key});

  @override
  State<StatefulWidget> createState() => _CparaDetailsWidgetState();
}

class _CparaDetailsWidgetState extends State<CparaDetailsWidget> {
  RadioButtonOptions? selected;
  RadioButtonOptions? isFirstAssessment;
  RadioButtonOptions? isChildHeaded;
  RadioButtonOptions? hasHivExposedInfant;
  RadioButtonOptions? hasPregnantOrBreastfeedingWoman;

  // final List<ChildDetails> children = [
  //   ChildDetails(
  //     name: 'John Doe',
  //     age: 10,
  //     gender: 'Male',
  //     uniqueNumber: '123456789',
  //     schoolLevel: 'Primary',
  //     registeredInProgram: true,
  //   ),
  //   ChildDetails(
  //     name: 'Jane Doe',
  //     age: 8,
  //     gender: 'Female',
  //     uniqueNumber: '987654321',
  //     schoolLevel: 'Kindergarten',
  //     registeredInProgram: false,
  //   ),
  // ];

  List<CaseLoadModel> children = [
  ];

  @override
  void initState() {
    DetailModel detailModel =
        context.read<CparaProvider>().detailModel ?? DetailModel();
    isFirstAssessment = detailModel.isFirstAssessment == null
        ? isFirstAssessment
        : convertingStringToRadioButtonOptions(detailModel.isFirstAssessment!);
    isChildHeaded = detailModel.isChildHeaded == null
        ? isChildHeaded
        : convertingStringToRadioButtonOptions(detailModel.isChildHeaded!);
    hasHivExposedInfant = detailModel.hasHivExposedInfant == null
        ? hasHivExposedInfant
        : convertingStringToRadioButtonOptions(
            detailModel.hasHivExposedInfant!);
    // dateOfAssessment = detailModel.dateOfAssessment == null ? dateOfAssessment : DateTime.parse(detailModel.dateOfAssessment!);
    // dateOfLastAssessment = detailModel.dateOfLastAssessment == null ? dateOfLastAssessment : DateTime.parse(detailModel.dateOfLastAssessment!);
    List<CaseLoadModel> models =
        context.read<CparaProvider>().children ?? [];
    children = models;

    super.initState();
  }

  void _getDataAndMoveToNext() {
    print('Is first assessment: $widget');
    print('Is child headed: $isChildHeaded');
    print('Has HIV exposed infant: $hasHivExposedInfant');
    print(
        'Has pregnant or breastfeeding woman: $hasPregnantOrBreastfeedingWoman');

    DateTime? dateOfAssessment =
        _dateTextFieldKey.currentState?.getSelectedDate();
    String formattedDateOfAssessment = dateOfAssessment != null
        ? DateFormat('yyyy-MM-dd').format(dateOfAssessment)
        : '';
    print('Date of assessment: $formattedDateOfAssessment');

    DateTime? dateOfPreviousAssessment =
        _dateTextFieldPreviousKey.currentState?.getSelectedDate();
    String formattedDateOfPreviousAssessment = dateOfPreviousAssessment != null
        ? DateFormat('yyyy-MM-dd').format(dateOfPreviousAssessment)
        : '';
    print('Date of previous assessment: $formattedDateOfPreviousAssessment');
  }

  final GlobalKey<_DateTextFieldState> _dateTextFieldKey = GlobalKey();
  final GlobalKey<_DateTextFieldState> _dateTextFieldPreviousKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return StepsWrapper(
      title: 'CPARA Details',
      children: [
        DateTextField(
          key: _dateTextFieldKey,
          label: 'Date of Assessment',
          enabled: true,
          identifier: DateTextFieldIdentifier.dateOfAssessment,
          onDateSelected: (date) {
            print('Date selected: $date');
            DetailModel detailModel =
                context.read<CparaProvider>().detailModel ?? DetailModel();
            context.read<CparaProvider>().updateDetailModel(
                detailModel.copyWith(dateOfAssessment: date.toString()));
          },
        ),
        const Divider(
          height: 20,
          thickness: 2,
        ),
        const SizedBox(height: 20),
        const TextViewsColumn(),
        QuestionWidget(
            question: 'Is this the first Case Plan Readiness Assessment?',
            selectedOption: (value) {
              setState(() {
                isFirstAssessment = value;
                if (isFirstAssessment == RadioButtonOptions.yes) {
                  _dateTextFieldPreviousKey.currentState?.clearDate();
                }
                DetailModel detailModel =
                    context.read<CparaProvider>().detailModel ?? DetailModel();
                String selectedOption =
                    convertingRadioButtonOptionsToString(value);
                context.read<CparaProvider>().updateDetailModel(
                    detailModel.copyWith(isFirstAssessment: selectedOption));
              });
            },
            isNaAvailable: false),
        const SizedBox(height: 20),
        DateTextField(
          key: _dateTextFieldPreviousKey,
          label: 'If No, give date of Previous Case Plan Readiness Assessment',
          enabled: isFirstAssessment == RadioButtonOptions.no,
          identifier: DateTextFieldIdentifier.previousAssessment,
          onDateSelected: (date) {
            print('Date selected: $date');
            DetailModel detailModel =
                context.read<CparaProvider>().detailModel ?? DetailModel();
            context.read<CparaProvider>().updateDetailModel(
                detailModel.copyWith(dateOfLastAssessment: date.toString()));
          },
        ),
        const SizedBox(height: 20),
        const ReusableTitleText(
            title:
                'Details of all children below 18 years currently living in the household.'),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          itemBuilder: (context, index) {
            return ExpansionTile(title: Text('${children[index].ovcFirstName!} ${children[index].ovcSurname!}'), children: [
              ChildCard(childDetails: children[index]),
            ]);
          },
        ),
        QuestionWidget(
            question:
                "Is this household child-headed (i.e. Household head age is less than 18 years)?",
            selectedOption: (value) {
              setState(() {
                DetailModel detailModel =
                    context.read<CparaProvider>().detailModel ?? DetailModel();
                String selectedOption =
                    convertingRadioButtonOptionsToString(value);
                context.read<CparaProvider>().updateDetailModel(
                    detailModel.copyWith(isChildHeaded: selectedOption));
              });
            },
            isNaAvailable: false),
        QuestionWidget(
            question: 'Does this HH have HIV exposed infant?',
            selectedOption: (value) {
              setState(() {
                hasHivExposedInfant = value;
                DetailModel detailModel =
                    context.read<CparaProvider>().detailModel ?? DetailModel();
                String selectedOption =
                    convertingRadioButtonOptionsToString(value);
                context.read<CparaProvider>().updateDetailModel(
                    detailModel.copyWith(hasHivExposedInfant: selectedOption));
              });
            },
            isNaAvailable: false),
        QuestionWidget(
            question:
                'Does this HH currently have a pregnant and/or breastfeeding woman/ adolescent?',
            selectedOption: (value) {
              setState(() {
                hasPregnantOrBreastfeedingWoman = value;
                DetailModel detailModel =
                    context.read<CparaProvider>().detailModel ?? DetailModel();
                String selectedOption =
                    convertingRadioButtonOptionsToString(value);
                context.read<CparaProvider>().updateDetailModel(detailModel
                    .copyWith(hasPregnantOrBreastfeedingWoman: selectedOption));
              });
            },
            isNaAvailable: false),
        const SizedBox(height: 20),
      ],
    );
  }
}

class DateTextField extends StatefulWidget {
  const DateTextField(
      {Key? key,
      required this.label,
      required this.enabled,
      required this.onDateSelected,
      required this.identifier})
      : super(key: key);

  final String label;
  final bool enabled;
  final DateTextFieldIdentifier identifier;
  final Function(DateTime?)? onDateSelected;

  @override
  _DateTextFieldState createState() => _DateTextFieldState();
}

class _DateTextFieldState extends State<DateTextField> {
  DateTime? selectedDate;

  void clearDate() {
    setState(() {
      selectedDate = null;
    });
  }

  DateTime? getSelectedDate() {
    return selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    String textFieldText = selectedDate != null
        ? DateFormat('MMMM d, yyyy').format(selectedDate!)
        : '';
    return TextField(
      onTap: () {
        if (widget.enabled) {
          showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          ).then((pickedDate) {
            if (pickedDate != null && mounted) {
              setState(() {
                selectedDate = pickedDate;
                widget.onDateSelected!(selectedDate);
              });
            }
          });
        }
      },
      readOnly: true,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      controller: TextEditingController(text: textFieldText),
    );
  }
}

// class class TextViewsColumn
class TextViewsColumn extends StatefulWidget {
  const TextViewsColumn({super.key});

  @override
  _TextViewsColumnState createState() => _TextViewsColumnState();
}

class _TextViewsColumnState extends State<TextViewsColumn> {
  CaseLoadModel caseLoadModel = CaseLoadModel();
  // SummaryDataModel dashData = SummaryDataModel();
  @override
  void initState() {
    super.initState();

    caseLoadModel =
        context.read<CparaProvider>().caseLoadModel ?? CaseLoadModel();

  }

  @override
  Widget build(BuildContext context) {
    final SummaryDataModel dashData =
    context.select((UIProvider provider) => provider.getDashData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReusableTitleText(title: 'Name of Organisation(LIP)'),
        const SizedBox(height: 10),
        Text(dashData.orgUnit),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Date enrolled in the project'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.registrationDate}"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: "County"),
        const SizedBox(height: 10),
        Text("details.countyName *"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Sub County'),
        const SizedBox(height: 10),
        Text("details.subCountyName *"),
        const SizedBox(height: 10),
        const ReusableTitleText(
            title: 'Name of caseworker/CHV conducting assessment'),
        const SizedBox(height: 10),
        Text("details.chvNames *"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Name of SDP staff/Case Manager'),
        const SizedBox(height: 10),
        Text(dashData.orgUnit),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Name of Caregiver'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.caregiverNames}"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Caregiver ID Number'),
        const SizedBox(height: 10),
        Text("${caseLoadModel.caregiverCpimsId}"),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Caregiver Gender'),
        const SizedBox(height: 10),
        Text("Female *"),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Caregiver DOB'),
        const SizedBox(height: 10),
        Text('August 21, 1973 *'),
        const SizedBox(height: 10),
        const ReusableTitleText(title: 'Caregiver Phone Number'),
        const SizedBox(height: 10),
        Text('708568702 *'),
        const SizedBox(height: 10),
        const Divider(height: 20, thickness: 2),
        const SizedBox(height: 20),
      ],
    );
  }
}

class ChildCard extends StatelessWidget {
  const ChildCard({Key? key, required this.childDetails}) : super(key: key);
  // CaseLoadModel caseLoadModel = CaseLoadModel();
  final CaseLoadModel childDetails;

  @override
  Widget build(BuildContext context) {
    // caseLoadModel =
    //     context.read<CparaProvider>().caseLoadModel ?? CaseLoadModel();
    // final careGiverChildren = allCaseLoadData
    //     .where((element) =>
    // element.caregiverNames == widget.caseLoadModel.caregiverNames)
    //     .toList();
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(title: 'Name'),
                SizedBox(
                  width: 10.0,
                ),
                ReusableTitleText(title: 'Age')
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${childDetails.ovcFirstName!} ${childDetails.ovcSurname!}'),
                Text("${calculateAge(childDetails.dateOfBirth!)} years"),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(title: 'Gender'),
                ReusableTitleText(title: 'Unique Number'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(childDetails.sex!),
                Text(childDetails.cpimsId!),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReusableTitleText(
                  title: 'School Level',
                ),
              ],
            ),
            //todo: change to be dynamic
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(""),
              ],
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FittedBox(
                    child: ReusableTitleText(
                        title: 'Registered in this OVC Program')),
              ],
            ),
            //todo: change to be dynamic
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Yes"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReusableTitleText extends StatelessWidget {
  const ReusableTitleText({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

class ChildDetails {
  final String name;
  final int age;
  final String gender;
  final String uniqueNumber;
  final String schoolLevel;
  final bool registeredInProgram;

  ChildDetails({
    required this.name,
    required this.age,
    required this.gender,
    required this.uniqueNumber,
    required this.schoolLevel,
    required this.registeredInProgram,
  });
}

class CparaOvcDetails {
  final String ovcCpimsId;
  final String ovcNames;
  final String dateOfBirth;
  final String ovcEnrollmentDate;
  final String exitStatus;
  final String exitDate;
  final int cboId;
  final String cboName;
  final int chvCpimsId;
  final String chvNames;
  final int caregiverCpimsId;
  final String caregiverNames;
  final String wardCode;
  final String wardName;

  CparaOvcDetails({
    required this.ovcCpimsId,
    required this.ovcNames,
    required this.dateOfBirth,
    required this.ovcEnrollmentDate,
    required this.exitStatus,
    required this.exitDate,
    required this.cboId,
    required this.cboName,
    required this.chvCpimsId,
    required this.chvNames,
    required this.caregiverCpimsId,
    required this.caregiverNames,
    required this.wardCode,
    required this.wardName,
  });

  factory CparaOvcDetails.fromJson(Map<String, dynamic> json) {
    return CparaOvcDetails(
      ovcCpimsId: json['ovc_cpims_id'],
      ovcNames: json['ovc_names'],
      dateOfBirth: json['date_of_birth'],
      ovcEnrollmentDate: json['ovc_enrollment_date'],
      exitStatus: json['exit_status'],
      exitDate: json['exit_date'],
      cboId: json['cbo_id'],
      cboName: json['cbo_name'],
      chvCpimsId: json['chv_cpims_id'],
      chvNames: json['chv_names'],
      caregiverCpimsId: json['caregiver_cpims_id'],
      caregiverNames: json['caregiver_names'],
      wardCode: json['ward']['code'],
      wardName: json['ward']['name'],
    );
  }
}

class ApiService {
  static Future<CparaOvcDetails> fetchOvcDetails(
      String token, String ovcCpimsId) async {
    final response = await http.get(
      Uri.parse('https://dev.cpims.net/api/form/CPR/?ovc_cpims_id=$ovcCpimsId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      print(response.body);
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return CparaOvcDetails.fromJson(jsonData);
    } else {
      throw Exception('Failed to load OVC details');
    }
  }
}

enum DateTextFieldIdentifier {
  dateOfAssessment,
  previousAssessment,
}
