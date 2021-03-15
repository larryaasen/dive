import 'package:bloc/bloc.dart';
import 'package:dive_core/dive_core.dart';
import 'package:equatable/equatable.dart';
import 'package:built_collection/built_collection.dart';

class DiveReferencePanel extends Equatable {
  DiveReferencePanel({this.assignedSource, String id})
      : this.id = id == null ? DiveUuid.newId() : id;

  final DiveSource assignedSource;
  final String id;

  DiveReferencePanel copyWith({
    DiveSource assignedSource,
    String id,
  }) {
    return DiveReferencePanel(
      assignedSource: assignedSource,
      id: id ?? this.id,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [assignedSource, id];
}

class DiveReferencePanels extends Equatable {
  const DiveReferencePanels({this.panels});

  DiveReferencePanels.initial() : this(panels: defaultPanels());

  static const maxPanelSources = 6;

  final BuiltList<DiveReferencePanel> panels;

  static BuiltList<DiveReferencePanel> defaultPanels() {
    return List<DiveReferencePanel>.generate(
        maxPanelSources, (index) => DiveReferencePanel()).build();
  }

  DiveReferencePanels copyWith({
    BuiltList<DiveReferencePanel> panels,
  }) {
    return DiveReferencePanels(
      panels: panels ?? this.panels,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [panels];
}

class DiveReferencePanelsCubit extends Cubit<DiveReferencePanels> {
  DiveReferencePanelsCubit() : super(DiveReferencePanels.initial());

  void assignSource(DiveSource source, DiveReferencePanel panel) {
    int panelIndex = state.panels.indexOf(panel);
    assert(panelIndex >= 0 && panelIndex < DiveReferencePanels.maxPanelSources);
    if (panelIndex < 0 || panelIndex >= DiveReferencePanels.maxPanelSources) {
      print("DiveReferencePanelsCubit.assignSource panel not found: $panel");
      return;
    }

    final newState = state.copyWith(
        panels: state.panels.rebuild((b) =>
            b[panelIndex] = b[panelIndex].copyWith(assignedSource: source)));

    emit(newState);
  }
}
