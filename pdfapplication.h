/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#ifndef PDFAPPLICATION_H
#define PDFAPPLICATION_H

#include <QGuiApplication>
#include <QObject>

class PdfApplication : public QGuiApplication
{
public:
    PdfApplication(int &argc, char **argv);
    void setFileOpener(QObject *opener) {
        m_fileOpener = opener;
    }

protected:
    bool event(QEvent *e) override;

    QObject *m_fileOpener;
};

#endif // PDFAPPLICATION_H
