TEMPLATE = app

QT += qml quick quickcontrols2 pdf svg

SOURCES += \
    main.cpp \
    pdfapplication.cpp \
    pdfattachmentmodel.cpp \
    pdfmanager.cpp \
    qpdflibwrapper.cpp

RESOURCES += \
    pdffeather.qrc

HEADERS += \
    pdfapplication.h \
    pdfattachmentmodel.h \
    pdfmanager.h \
    qpdflibwrapper.h

INCLUDEPATH += 3rdparty/qpdf-11.3.0-msvc64/include
LIBS += -L"3rdparty/qpdf-11.3.0-msvc64/lib" -lqpdf

RC_ICONS = images/feather.ico
