/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

#ifndef PDFMANAGER_H
#define PDFMANAGER_H

#include <QObject>
#include <QUrl>
#include <QString>
#include <QMap>

#include "pdfattachmentmodel.h"
#include "qpdflibwrapper.h"

class PdfManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool saved MEMBER m_changes_saved NOTIFY savedChanged)


public:
    PdfManager(PdfAttachmentModel *model, QObject *parent = nullptr);
    ~PdfManager();

public:

    QString getHeaderText();
    int getAttachmentPolicy ();

private:
    void pendingSaves(bool status);

public slots:
    void loadPdf(const QUrl &file, const QString &password);
    bool savePdf(const QUrl &file);

    void addEmbedFile(const QUrl &url);
    void addEmbedFiles(const QList<QUrl> &files);
    void removeEmbedFile(const QString &key);
    void removeEmbedFiles(const QList<QString> &keys);
    bool saveEmbedFile(const QString &key, const QUrl &path);
    bool saveAllEmbedFiles(const QUrl &path);
    bool openEmbedFile(const QString &key);

    void replaceMetadata(const QString &key, const QString &value);

    void setHeaderText(const QString &text);
    void setAttachmentPolicy(int level);

signals:
    void savedChanged();

private:
    QUrl m_pdf_url;
    QString m_password;

    QString m_temp_folder;                      // Temporal folder for opening embed files

    QPDFLibWrapper m_qpdf_lib;
    PdfAttachmentModel *m_attach_model;         // Model for displaying objects

    // Configuration
    int m_attachment_policy_level;              // 1 (only of new files); 2 (always); others (never)
    QString m_header_text;                      // Header text for putting before a list

    // Control of changes in current pdf
    bool m_changes_saved;                       // To control if document/pdf has changes to be saved in disk    
};

#endif // PDFMANAGER_H
