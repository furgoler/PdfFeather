/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#include "pdfapplication.h"
#include "pdfattachmentmodel.h"
#include "pdfmanager.h"

#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QtQml>

int main(int argc, char* argv[])
{
    // Create Qt/QML Objets
    PdfApplication app(argc, argv);
    app.setApplicationName("PDF Feather");
    app.setOrganizationName("Furgoler Software");
    app.setApplicationVersion(QT_VERSION_STR);

    // This overrides qtquickcontrols2.conf control styled defined, but not the remaining parameters
    // Used Material as Fusion Dark is not available at this momment and Universal is not beauty enough
    //QQuickStyle::setStyle("Material");

    QQmlApplicationEngine engine;

    // Registering the manager and the model for PDF attachments
    PdfAttachmentModel pdf_attachments;
    PdfManager pdf_manager(&pdf_attachments);
    engine.rootContext()->setContextProperty("pdfattachmentmodel",&pdf_attachments);
    engine.rootContext()->setContextProperty("pdfmanager",&pdf_manager);

    // Load main QML
    engine.load(QUrl(QStringLiteral("qrc:///qml/PdfFeather.qml")));

    // Open file from argv and register propery for initial file
    QObject *root = engine.rootObjects().constFirst();
    app.setFileOpener(engine.rootObjects().constFirst());
    if (app.arguments().count() > 1)
    {
        QUrl toLoad = QUrl::fromUserInput(app.arguments().at(1));
        root->setProperty("source", toLoad);
    }

    return app.exec();
}
