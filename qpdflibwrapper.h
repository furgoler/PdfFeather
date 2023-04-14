/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#ifndef QPDFLIBWRAPPER_H
#define QPDFLIBWRAPPER_H

#include <QObject>
#include <QString>
#include <QList>
#include <QMap>

#include <qpdf/QPDF.hh>

class QPDFLibWrapper : public QObject
{
    Q_OBJECT
public:
    QPDFLibWrapper(QObject *parent = nullptr);
    ~QPDFLibWrapper();

    void loadpdf(const QString &file, const QString &password);
    bool savepdf(const QString &file);

    QList<QString> getEmbeddedFiles();
    void addEmbeddedFiles(const QList<QString> &paths);
    void removeEmbeddedFiles(const QList<QString> &keys);
    bool exportEmbedFile(const QString &key, const QString &filename);

    void updateMedatadaInfo(const QString &key, const QString &value);
    void updateMedatadaInfo(QMap<QString, QString> &metadata);

    int getNumberOfPages();
    void createEmptyPdf();
    void addEmptyPage(int x_size, int y_size);
    void addPagesOfNames(QList<QString> names, int x_size, int y_size, int x_margin, int y_margin, int font_size, int interline, int font_size_header, const QString &header);

private:
    void initQPDF();
    void closeQPDF();
    QPDFObjectHandle createEmptyPage(int x_size, int y_size);

private:
    QPDF *m_qpdf;
};

#endif // QPDFLIBWRAPPER_H
