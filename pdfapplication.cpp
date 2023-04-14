/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#include "pdfapplication.h"
#include <QFileOpenEvent>

PdfApplication::PdfApplication(int &argc, char **argv)
    : QGuiApplication(argc, argv)
{
}

bool PdfApplication::event(QEvent *e)
{
    if (e->type() == QEvent::FileOpen)
    {
        QFileOpenEvent *foEvent = static_cast<QFileOpenEvent *>(e);
        m_fileOpener->setProperty("source", foEvent->url());
    }
    return QGuiApplication::event(e);
}
